<?php

/*
 +-----------------------------------------------------------------------+
 | This file is part of the Roundcube Webmail client                     |
 |                                                                       |
 | Copyright (C) The Roundcube Dev Team                                  |
 |                                                                       |
 | Licensed under the GNU General Public License version 3 or            |
 | any later version with exceptions for skins & plugins.                |
 | See the README file for a full license statement.                     |
 |                                                                       |
 | PURPOSE:                                                              |
 |   Interface to the local address book database                        |
 +-----------------------------------------------------------------------+
 | Author: Thomas Bruederli <roundcube@gmail.com>                        |
 +-----------------------------------------------------------------------+
*/

/**
 * Model class for the local address book database
 */
class rcube_contacts extends rcube_addressbook
{
    // protected for backward compat. with some plugins
    protected $db_name = 'contacts';
    protected $db_groups = 'contactgroups';
    protected $db_groupmembers = 'contactgroupmembers';
    protected $vcard_fieldmap = [];

    /**
     * Store database connection.
     *
     * @var rcube_db
     */
    protected $db;
    protected $user_id = 0;
    protected $filter;
    protected $result;
    protected $cache;
    protected $table_cols = ['name', 'email', 'firstname', 'surname'];
    protected $fulltext_cols = ['name', 'firstname', 'surname', 'middlename', 'nickname',
        'jobtitle', 'organization', 'department', 'maidenname', 'email', 'phone',
        'address', 'street', 'locality', 'zipcode', 'region', 'country', 'website', 'im', 'notes'];

    // public properties
    public $primary_key = 'contact_id';
    public $name;
    public $readonly = false;
    public $groups = true;
    public $undelete = true;
    public $list_page = 1;
    public $page_size = 10;
    public $group_id = 0;
    public $ready = false;
    public $coltypes = ['name', 'firstname', 'surname', 'middlename', 'prefix', 'suffix', 'nickname',
        'jobtitle', 'organization', 'department', 'assistant', 'manager',
        'gender', 'maidenname', 'spouse', 'email', 'phone', 'address',
        'birthday', 'anniversary', 'website', 'im', 'notes', 'photo'];
    public $date_cols = ['birthday', 'anniversary'];

    public const SEPARATOR = ',';

    /**
     * Object constructor
     *
     * @param rcube_db $dbconn Instance of the rcube_db class
     * @param int      $user   User-ID
     */
    public function __construct($dbconn, $user)
    {
        $this->db = $dbconn;
        $this->user_id = $user;
        $this->ready = !$this->db->is_error();
    }

    /**
     * Returns addressbook name
     *
     * @return string
     */
    #[Override]
    public function get_name()
    {
        return $this->name;
    }

    /**
     * Save a search string for future listings
     *
     * @param mixed $filter SQL params to use in listing method
     */
    #[Override]
    public function set_search_set($filter): void
    {
        $this->filter = $filter;
        $this->cache = null;
    }

    /**
     * Getter for saved search properties
     *
     * @return mixed Search properties used by this class
     */
    #[Override]
    public function get_search_set()
    {
        return $this->filter;
    }

    /**
     * Setter for the current group
     * (empty, has to be re-implemented by extending class)
     */
    #[Override]
    public function set_group($gid)
    {
        $this->group_id = $gid;
        $this->cache = null;
    }

    /**
     * Reset all saved results and search parameters
     */
    #[Override]
    public function reset(): void
    {
        $this->result = null;
        $this->filter = null;
        $this->cache = null;
    }

    /**
     * List all active contact groups of this source
     *
     * @param ?string $search Search string to match group name
     * @param int     $mode   Matching mode. Sum of rcube_addressbook::SEARCH_*
     *
     * @return array Indexed list of contact groups, each a hash array
     */
    #[Override]
    public function list_groups($search = null, $mode = 0)
    {
        $results = [];

        if (!$this->groups) {
            return $results;
        }

        $sql_filter = '';

        if ($search) {
            if ($mode & rcube_addressbook::SEARCH_STRICT) {
                $sql_filter = $this->db->ilike('name', $search);
            } elseif ($mode & rcube_addressbook::SEARCH_PREFIX) {
                $sql_filter = $this->db->ilike('name', $search . '%');
            } else {
                $sql_filter = $this->db->ilike('name', '%' . $search . '%');
            }

            $sql_filter = " AND {$sql_filter}";
        }

        $sql_result = $this->db->query(
            'SELECT * FROM ' . $this->db->table_name($this->db_groups, true)
            . ' WHERE `del` <> 1 AND `user_id` = ?' . $sql_filter
            . ' ORDER BY `name`',
            $this->user_id
        );

        while ($sql_result && ($sql_arr = $this->db->fetch_assoc($sql_result))) {
            $sql_arr['ID'] = $sql_arr['contactgroup_id'];
            $results[] = $sql_arr;
        }

        return $results;
    }

    /**
     * Get group properties such as name and email address(es)
     *
     * @param string $group_id Group identifier
     *
     * @return ?array group properties as hash array, null in case of error
     */
    #[Override]
    public function get_group($group_id)
    {
        $sql_result = $this->db->query(
            'SELECT * FROM ' . $this->db->table_name($this->db_groups, true)
            . ' WHERE `del` <> 1 AND `contactgroup_id` = ? AND `user_id` = ?',
            $group_id, $this->user_id
        );

        if ($sql_result && ($sql_arr = $this->db->fetch_assoc($sql_result))) {
            $sql_arr['ID'] = $sql_arr['contactgroup_id'];
            return $sql_arr;
        }

        return null;
    }

    /**
     * List the current set of contact records
     *
     * @param ?array $cols    List of cols to show, Null means all
     * @param int    $subset  Only return this number of records, use negative values for tail
     * @param bool   $nocount True to skip the count query (select only)
     *
     * @return rcube_result_set Indexed list of contact records, each a hash array
     */
    #[Override]
    public function list_records($cols = null, $subset = 0, $nocount = false)
    {
        if ($nocount || $this->list_page <= 1) {
            // create dummy result, we don't need a count now
            $this->result = new rcube_result_set();
        } else {
            // count all records
            $this->result = $this->count();
        }

        $start_row = $subset < 0 ? $this->result->first + $this->page_size + $subset : $this->result->first;
        $length = $subset != 0 ? abs($subset) : $this->page_size;
        $join = '';

        if ($this->group_id) {
            $join = ' LEFT JOIN ' . $this->db->table_name($this->db_groupmembers, true) . ' AS m'
                . ' ON (m.`contact_id` = c.`' . $this->primary_key . '`)';
        }

        $order_col = in_array($this->sort_col, $this->table_cols) ? $this->sort_col : 'name';
        $order_cols = ["c.`{$order_col}`"];

        if ($order_col == 'firstname') {
            $order_cols[] = 'c.`surname`';
        } elseif ($order_col == 'surname') {
            $order_cols[] = 'c.`firstname`';
        }
        if ($order_col != 'name') {
            $order_cols[] = 'c.`name`';
        }
        $order_cols[] = 'c.`email`';

        $sql_result = $this->db->limitquery(
            'SELECT * FROM ' . $this->db->table_name($this->db_name, true) . ' AS c'
            . $join
            . ' WHERE c.`del` <> 1'
                . ' AND c.`user_id` = ?'
                . ($this->group_id ? ' AND m.`contactgroup_id` = ?' : '')
                . ($this->filter ? ' AND ' . $this->filter : '')
            . ' ORDER BY ' . $this->db->concat($order_cols) . ' ' . $this->sort_order,
            $start_row,
            $length,
            $this->user_id,
            $this->group_id
        );

        // determine whether we have to parse the vcard or if only db cols are requested
        $read_vcard = !$cols || count(array_intersect($cols, $this->table_cols)) < count($cols);

        while ($sql_result && ($sql_arr = $this->db->fetch_assoc($sql_result))) {
            $sql_arr['ID'] = $sql_arr[$this->primary_key];

            if ($read_vcard) {
                $sql_arr = $this->convert_db_data($sql_arr);
            } else {
                $sql_arr['email'] = $sql_arr['email'] ? explode(self::SEPARATOR, $sql_arr['email']) : [];
                $sql_arr['email'] = array_map('trim', $sql_arr['email']);
            }

            $this->result->add($sql_arr);
        }

        $cnt = count($this->result->records);

        // update counter
        if ($nocount) {
            $this->result->count = $cnt;
        } elseif ($this->list_page <= 1) {
            if ($cnt < $this->page_size && $subset == 0) {
                $this->result->count = $cnt;
            } elseif (isset($this->cache['count'])) {
                $this->result->count = $this->cache['count'];
            } else {
                $this->result->count = $this->_count();
            }
        }

        return $this->result;
    }

    /**
     * Search contacts
     *
     * @param mixed        $fields   The field name or array of field names to search in
     * @param mixed        $value    Search value (or array of values when $fields is array)
     * @param int          $mode     Search mode. Sum of rcube_addressbook::SEARCH_*
     * @param bool         $select   True if results are requested, False if count only
     * @param bool         $nocount  True to skip the count query (select only)
     * @param string|array $required List of fields that cannot be empty
     *
     * @return rcube_result_set Contact records and 'count' value
     */
    #[Override]
    public function search($fields, $value, $mode = 0, $select = true, $nocount = false, $required = [])
    {
        if (!is_array($required) && !empty($required)) {
            $required = [$required];
        }

        $where = $post_search = [];
        $mode = intval($mode);

        // direct ID search
        if ($fields == 'ID' || $fields == $this->primary_key) {
            $ids = !is_array($value) ? explode(self::SEPARATOR, $value) : $value;
            $ids = $this->db->array2list($ids, 'integer');
            $where[] = 'c.' . $this->primary_key . ' IN (' . $ids . ')';
        } elseif (is_array($value)) {
            foreach ((array) $fields as $idx => $col) {
                $val = $value[$idx];

                if (!strlen($val)) {
                    continue;
                }

                // table column
                if (in_array($col, $this->table_cols)) {
                    $where[] = $this->fulltext_sql_where($val, $mode, $col);
                }
                // vCard field
                else {
                    if (in_array($col, $this->fulltext_cols)) {
                        $where[] = $this->fulltext_sql_where($val, $mode, 'words');
                    }
                    $post_search[$col] = mb_strtolower($val);
                }
            }
        }
        // fulltext search in all fields
        elseif ($fields == '*') {
            $where[] = $this->fulltext_sql_where($value, $mode, 'words');
        } else {
            // require each word in to be present in one of the fields
            $words = ($mode & rcube_addressbook::SEARCH_STRICT) ? [$value] : rcube_utils::tokenize_string($value, 1);
            foreach ($words as $word) {
                $groups = [];
                foreach ((array) $fields as $idx => $col) {
                    // table column
                    if (in_array($col, $this->table_cols)) {
                        $groups[] = $this->fulltext_sql_where($word, $mode, $col);
                    }
                    // vCard field
                    else {
                        if (in_array($col, $this->fulltext_cols)) {
                            $groups[] = $this->fulltext_sql_where($word, $mode, 'words');
                        }
                    }
                }
                $where[] = '(' . implode(' OR ', $groups) . ')';
            }
        }

        foreach (array_intersect($required, $this->table_cols) as $col) {
            $where[] = $this->db->quote_identifier($col) . ' <> ' . $this->db->quote('');
        }
        $required = array_diff($required, $this->table_cols);

        if (!empty($where)) {
            // use AND operator for advanced searches
            $where = implode(' AND ', $where);
        }

        // Post-searching in vCard data fields
        // we will search in all records and then build a where clause for their IDs
        if (!empty($post_search) || !empty($required)) {
            $ids = [0];
            // build key name regexp
            $regexp = '/^(' . implode('|', array_keys($post_search)) . ')(?:.*)$/';
            // use initial WHERE clause, to limit records number if possible
            if (!empty($where)) {
                $this->set_search_set($where);
            }

            // count result pages
            $cnt = $this->count()->count;
            $pages = ceil($cnt / $this->page_size);
            $scnt = !empty($post_search) ? count($post_search) : 0;

            // get (paged) result
            for ($i = 0; $i < $pages; $i++) {
                $this->list_records(null, $i, true);

                foreach ($this->result as $row) {
                    $id = $row[$this->primary_key];
                    $found = [];
                    if (!empty($post_search)) {
                        foreach (preg_grep($regexp, array_keys($row)) as $col) {
                            $pos = strpos($col, ':');
                            $colname = $pos ? substr($col, 0, $pos) : $col;
                            $search = $post_search[$colname];
                            foreach ((array) $row[$col] as $_value) {
                                if ($this->compare_search_value($colname, $_value, $search, $mode)) {
                                    $found[$colname] = true;
                                    break;
                                }
                            }
                        }
                    }

                    // check if required fields are present
                    if (!empty($required)) {
                        foreach ($required as $req) {
                            $hit = false;
                            foreach (array_keys($row) as $c) {
                                if ($c === $req || str_starts_with($c, $req . ':')) {
                                    if ((is_string($row[$c]) && strlen($row[$c])) || !empty($row[$c])) {
                                        $hit = true;
                                        break;
                                    }
                                }
                            }
                            if (!$hit) {
                                continue 2;
                            }
                        }
                    }

                    // all fields match
                    if (count($found) >= $scnt) {
                        $ids[] = $id;
                    }
                }
            }

            // build WHERE clause
            $ids = $this->db->array2list($ids, 'integer');
            $where = 'c.`' . $this->primary_key . '` IN (' . $ids . ')';
            // reset counter
            unset($this->cache['count']);

            // when we know we have an empty result
            if ($ids == '0') {
                $this->set_search_set($where);
                return $this->result = new rcube_result_set();
            }
        }

        if (!empty($where)) {
            $this->set_search_set($where);
            if ($select) {
                $this->list_records(null, 0, $nocount);
            } else {
                $this->result = $this->count();
            }
        } else {
            return $this->result = new rcube_result_set();
        }

        return $this->result;
    }

    /**
     * Helper method to compose SQL where statements for fulltext searching
     */
    protected function fulltext_sql_where($value, $mode, $col = 'words', $bool = 'AND')
    {
        $AS = $col == 'words' ? ' ' : self::SEPARATOR;
        $words = $col == 'words' ? rcube_utils::normalize_string($value, true, 1) : [$value];

        $where = [];
        foreach ($words as $word) {
            if ($mode & rcube_addressbook::SEARCH_STRICT) {
                $where[] = '(' . $this->db->ilike($col, $word)
                    . ' OR ' . $this->db->ilike($col, $word . $AS . '%')
                    . ' OR ' . $this->db->ilike($col, '%' . $AS . $word . $AS . '%')
                    . ' OR ' . $this->db->ilike($col, '%' . $AS . $word) . ')';
            } elseif ($mode & rcube_addressbook::SEARCH_PREFIX) {
                $where[] = '(' . $this->db->ilike($col, $word . '%')
                    . ' OR ' . $this->db->ilike($col, '%' . $AS . $word . '%') . ')';
            } else {
                $where[] = $this->db->ilike($col, '%' . $word . '%');
            }
        }

        return count($where) ? '(' . implode(" {$bool} ", $where) . ')' : '';
    }

    /**
     * Count number of available contacts in database
     *
     * @return rcube_result_set Result object
     */
    #[Override]
    public function count()
    {
        $count = $this->cache['count'] ?? $this->_count();

        return new rcube_result_set($count, ($this->list_page - 1) * $this->page_size);
    }

    /**
     * Count number of available contacts in database
     *
     * @return int Contacts count
     */
    protected function _count()
    {
        $join = null;

        if ($this->group_id) {
            $join = ' LEFT JOIN ' . $this->db->table_name($this->db_groupmembers, true) . ' AS m'
                . ' ON (m.`contact_id` = c.`' . $this->primary_key . '`)';
        }

        // count contacts for this user
        $sql_result = $this->db->query(
            'SELECT COUNT(c.`contact_id`) AS cnt'
            . ' FROM ' . $this->db->table_name($this->db_name, true) . ' AS c'
                . $join
            . ' WHERE c.`del` <> 1'
            . ' AND c.`user_id` = ?'
            . ($this->group_id ? ' AND m.`contactgroup_id` = ?' : '')
            . ($this->filter ? ' AND (' . $this->filter . ')' : ''),
            $this->user_id,
            $this->group_id
        );

        $sql_arr = $this->db->fetch_assoc($sql_result);

        $this->cache['count'] = !empty($sql_arr) ? (int) $sql_arr['cnt'] : 0;

        return $this->cache['count'];
    }

    /**
     * Return the last result set
     *
     * @return rcube_result_set|null Result array or NULL if nothing selected yet
     */
    #[Override]
    public function get_result()
    {
        return $this->result;
    }

    /**
     * Get a specific contact record
     *
     * @param mixed $id    Record identifier(s)
     * @param bool  $assoc Enables returning associative array
     *
     * @return rcube_result_set|array|null Result object with all record fields
     */
    #[Override]
    public function get_record($id, $assoc = false)
    {
        // return cached result
        if ($this->result && ($first = $this->result->first()) && $first[$this->primary_key] == $id) {
            return $assoc ? $first : $this->result;
        }

        $this->db->query(
            'SELECT * FROM ' . $this->db->table_name($this->db_name, true)
            . ' WHERE `contact_id` = ?'
                . ' AND `user_id` = ?'
                . ' AND `del` <> 1',
            $id,
            $this->user_id
        );

        $this->result = null;

        if ($sql_arr = $this->db->fetch_assoc()) {
            $record = $this->convert_db_data($sql_arr);
            $this->result = new rcube_result_set(1);
            $this->result->add($record);
        }

        return $assoc && !empty($record) ? $record : $this->result;
    }

    /**
     * Get group assignments of a specific contact record
     *
     * @param mixed $id Record identifier
     *
     * @return array List of assigned groups, indexed by a group ID
     */
    #[Override]
    public function get_record_groups($id)
    {
        $results = [];

        if (!$this->groups) {
            return $results;
        }

        $sql_result = $this->db->query(
            'SELECT cgm.`contactgroup_id`, cg.`name` '
            . ' FROM ' . $this->db->table_name($this->db_groupmembers, true) . ' AS cgm'
            . ' LEFT JOIN ' . $this->db->table_name($this->db_groups, true) . ' AS cg'
                . ' ON (cgm.`contactgroup_id` = cg.`contactgroup_id` AND cg.`del` <> 1)'
            . ' WHERE cgm.`contact_id` = ?',
            $id
        );

        while ($sql_result && ($sql_arr = $this->db->fetch_assoc($sql_result))) {
            $results[$sql_arr['contactgroup_id']] = $sql_arr['name'];
        }

        return $results;
    }

    /**
     * Check the given data before saving.
     * If input not valid, the message to display can be fetched using get_error()
     *
     * @param array &$save_data Associative array with data to save
     * @param bool  $autofix    Try to fix/complete record automatically
     *
     * @return bool true if input is valid, False if not
     */
    #[Override]
    public function validate(&$save_data, $autofix = false)
    {
        // validate e-mail addresses
        $valid = parent::validate($save_data, $autofix);

        // require at least some name or email
        if ($valid) {
            $name = ($save_data['firstname'] ?? '')
                . ($save_data['surname'] ?? '')
                . ($save_data['name'] ?? '');

            if (!strlen($name) && !count(array_filter($this->get_col_values('email', $save_data, true)))) {
                $this->set_error(self::ERROR_VALIDATE, 'nonamewarning');
                $valid = false;
            }
        }

        return $valid;
    }

    /**
     * Create a new contact record
     *
     * @param array $save_data Associative array with save data
     * @param bool  $check     Enables validity checks
     *
     * @return mixed The created record ID on success, False on error
     */
    #[Override]
    public function insert($save_data, $check = false)
    {
        $insert_id = $existing = false;

        if ($check) {
            foreach ($save_data as $col => $values) {
                if (str_starts_with($col, 'email')) {
                    foreach ((array) $values as $email) {
                        $existing = $this->search('email', $email, false, false);
                        if ($existing->count) {
                            break 2;
                        }
                    }
                }
            }
        }

        $save_data = $this->convert_save_data($save_data);
        $a_insert_cols = $a_insert_values = [];

        foreach ($save_data as $col => $value) {
            $a_insert_cols[] = $this->db->quote_identifier($col);
            $a_insert_values[] = $this->db->quote($value);
        }

        if ((empty($existing) || empty($existing->count)) && !empty($a_insert_cols)) {
            $this->db->query(
                'INSERT INTO ' . $this->db->table_name($this->db_name, true)
                . ' (`user_id`, `changed`, `del`, ' . implode(', ', $a_insert_cols) . ')'
                . ' VALUES (' . intval($this->user_id) . ', ' . $this->db->now() . ', 0, ' . implode(', ', $a_insert_values) . ')'
            );

            $insert_id = $this->db->insert_id($this->db_name);
        }

        $this->cache = null;

        return $insert_id;
    }

    /**
     * Update a specific contact record
     *
     * @param mixed $id        Record identifier
     * @param array $save_cols Associative array with save data
     *
     * @return bool True on success, False on error
     */
    #[Override]
    public function update($id, $save_cols)
    {
        $updated = false;
        $write_sql = [];
        $record = $this->get_record($id, true);
        $save_cols = $this->convert_save_data($save_cols, $record);

        foreach ($save_cols as $col => $value) {
            $write_sql[] = sprintf('%s=%s', $this->db->quote_identifier($col), $this->db->quote($value));
        }

        if (!empty($write_sql)) {
            $this->db->query(
                'UPDATE ' . $this->db->table_name($this->db_name, true)
                . ' SET `changed` = ' . $this->db->now() . ', ' . implode(', ', $write_sql)
                . ' WHERE `contact_id` = ?'
                    . ' AND `user_id` = ?'
                    . ' AND `del` <> 1',
                $id,
                $this->user_id
            );

            $updated = $this->db->affected_rows();
            $this->result = null;  // clear current result (from get_record())
        }

        return !empty($updated);
    }

    /**
     * Convert data stored in the database into output format
     */
    private function convert_db_data($sql_arr)
    {
        $record = [
            'ID' => $sql_arr[$this->primary_key],
        ];

        if ($sql_arr['vcard']) {
            unset($sql_arr['email']);
            $vcard = new rcube_vcard($sql_arr['vcard'], RCUBE_CHARSET, false, $this->vcard_fieldmap);
            $record += $vcard->get_assoc() + $sql_arr;
        } else {
            $record += $sql_arr;
            $record['email'] = explode(self::SEPARATOR, $record['email']);
            $record['email'] = array_map('trim', $record['email']);
        }

        return $record;
    }

    /**
     * Convert input data for storing in the database
     */
    private function convert_save_data($save_data, $record = [])
    {
        $out = [];
        $words = '';

        if (!empty($record['vcard'])) {
            $vcard = $record['vcard'];
        } elseif (!empty($save_data['vcard'])) {
            $vcard = $save_data['vcard'];
        } else {
            $vcard = '';
        }

        // copy values into vcard object
        $vcard = new rcube_vcard($vcard, RCUBE_CHARSET, false, $this->vcard_fieldmap);
        $vcard->reset();

        // don't store groups in vCard (#1490277)
        $vcard->set('groups', null);
        unset($save_data['groups']);

        foreach ($save_data as $key => $values) {
            [$field, $section] = rcube_utils::explode(':', $key);

            $fulltext = in_array($field, $this->fulltext_cols);

            // avoid casting DateTime objects to array
            if (is_object($values) && is_a($values, 'DateTime')) {
                $values = [$values];
            }
            foreach ((array) $values as $value) {
                if (isset($value)) {
                    $vcard->set($field, $value, $section);
                }
                if ($fulltext && is_array($value)) {
                    $words .= ' ' . rcube_utils::normalize_string(implode(' ', $value));
                } elseif ($fulltext && strlen($value) >= 3) {
                    $words .= ' ' . rcube_utils::normalize_string($value);
                }
            }
        }

        $out['vcard'] = $vcard->export(false);

        foreach ($this->table_cols as $col) {
            $key = $col;
            if (!isset($save_data[$key])) {
                $key .= ':home';
            }
            if (isset($save_data[$key])) {
                if (is_array($save_data[$key])) {
                    $out[$col] = implode(self::SEPARATOR, $save_data[$key]);
                } else {
                    $out[$col] = $save_data[$key];
                }
            }
        }

        // save all e-mails in the database column
        if (!empty($vcard->email)) {
            $out['email'] = implode(self::SEPARATOR, $vcard->email);
        } else {
            $out['email'] = $save_data['email'] ?? '';
        }

        // join words for fulltext search
        $out['words'] = implode(' ', array_unique(explode(' ', $words)));

        return $out;
    }

    /**
     * Mark one or more contact records as deleted
     *
     * @param array|string $ids   Record identifiers array or string separated with self::SEPARATOR
     * @param bool         $force Remove record(s) irreversible (unsupported)
     *
     * @return int|false Number of removed records, False on failure
     */
    #[Override]
    public function delete($ids, $force = true)
    {
        if (!is_array($ids)) {
            $ids = explode(self::SEPARATOR, $ids);
        }

        $ids = $this->db->array2list($ids, 'integer');

        // flag record as deleted (always)
        $this->db->query(
            'UPDATE ' . $this->db->table_name($this->db_name, true)
            . ' SET `del` = 1, `changed` = ' . $this->db->now()
            . ' WHERE `user_id` = ?'
                . " AND `contact_id` IN ({$ids})",
            $this->user_id
        );

        $this->cache = null;

        return $this->db->affected_rows();
    }

    /**
     * Undelete one or more contact records
     *
     * @param array|string $ids Record identifiers array or string separated with self::SEPARATOR
     *
     * @return int Number of undeleted contact records
     */
    #[Override]
    public function undelete($ids)
    {
        if (!is_array($ids)) {
            $ids = explode(self::SEPARATOR, $ids);
        }

        $ids = $this->db->array2list($ids, 'integer');

        // clear deleted flag
        $this->db->query(
            'UPDATE ' . $this->db->table_name($this->db_name, true)
            . ' SET `del` = 0, `changed` = ' . $this->db->now()
            . ' WHERE `user_id` = ?'
                . " AND `contact_id` IN ({$ids})",
            $this->user_id
        );

        $this->cache = null;

        return $this->db->affected_rows();
    }

    /**
     * Remove all records from the database
     *
     * @param bool $with_groups Remove also groups
     *
     * @return int Number of removed records
     */
    #[Override]
    public function delete_all($with_groups = false)
    {
        $this->cache = null;

        $now = $this->db->now();

        $this->db->query('UPDATE ' . $this->db->table_name($this->db_name, true)
            . " SET `del` = 1, `changed` = {$now}"
            . ' WHERE `user_id` = ?', $this->user_id);

        $count = $this->db->affected_rows();

        if ($with_groups) {
            $this->db->query('UPDATE ' . $this->db->table_name($this->db_groups, true)
                . " SET `del` = 1, `changed` = {$now}"
                . ' WHERE `user_id` = ?', $this->user_id);

            $count += $this->db->affected_rows();
        }

        return $count;
    }

    /**
     * Create a contact group with the given name
     *
     * @param string $name The group name
     *
     * @return array|false False on error, array with record props in success
     */
    #[Override]
    public function create_group($name)
    {
        $result = false;

        // make sure we have a unique name
        $name = $this->unique_groupname($name);

        $this->db->query(
            'INSERT INTO ' . $this->db->table_name($this->db_groups, true)
            . ' (`user_id`, `changed`, `name`)'
            . ' VALUES (' . intval($this->user_id) . ', ' . $this->db->now() . ', ' . $this->db->quote($name) . ')'
        );

        if ($insert_id = $this->db->insert_id($this->db_groups)) {
            $result = ['id' => $insert_id, 'name' => $name];
        }

        return $result;
    }

    /**
     * Delete the given group (and all linked group members)
     *
     * @param string $gid Group identifier
     *
     * @return bool True on success, false if no data was changed
     */
    #[Override]
    public function delete_group($gid)
    {
        // flag group record as deleted
        $sql_result = $this->db->query(
            'UPDATE ' . $this->db->table_name($this->db_groups, true)
            . ' SET `del` = 1, `changed` = ' . $this->db->now()
            . ' WHERE `contactgroup_id` = ?'
                . ' AND `user_id` = ?',
            $gid, $this->user_id
        );

        $this->cache = null;

        return $this->db->affected_rows($sql_result) > 0;
    }

    /**
     * Rename a specific contact group
     *
     * @param string $gid     Group identifier
     * @param string $name    New name to set for this group
     * @param string $new_gid (not used)
     *
     * @return string|false New name on success, false if no data was changed
     */
    #[Override]
    public function rename_group($gid, $name, &$new_gid)
    {
        // make sure we have a unique name
        $name = $this->unique_groupname($name);

        $sql_result = $this->db->query(
            'UPDATE ' . $this->db->table_name($this->db_groups, true)
            . ' SET `name` = ?, `changed` = ' . $this->db->now()
            . ' WHERE `contactgroup_id` = ?'
                . ' AND `user_id` = ?',
            $name, $gid, $this->user_id
        );

        return $this->db->affected_rows($sql_result) ? $name : false;
    }

    /**
     * Add the given contact records the a certain group
     *
     * @param string       $group_id Group identifier
     * @param array|string $ids      List of contact identifiers to be added
     *
     * @return int Number of contacts added
     */
    #[Override]
    public function add_to_group($group_id, $ids)
    {
        if (!is_array($ids)) {
            $ids = explode(self::SEPARATOR, $ids);
        }

        $added = 0;
        $exists = [];

        // get existing assignments ...
        $sql_result = $this->db->query(
            'SELECT `contact_id` FROM ' . $this->db->table_name($this->db_groupmembers, true)
            . ' WHERE `contactgroup_id` = ?'
                . ' AND `contact_id` IN (' . $this->db->array2list($ids, 'integer') . ')',
            $group_id
        );

        while ($sql_result && ($sql_arr = $this->db->fetch_assoc($sql_result))) {
            $exists[] = $sql_arr['contact_id'];
        }

        // ... and remove them from the list
        $ids = array_diff($ids, $exists);

        foreach ($ids as $contact_id) {
            $this->db->query(
                'INSERT INTO ' . $this->db->table_name($this->db_groupmembers, true)
                . ' (`contactgroup_id`, `contact_id`, `created`)'
                . ' VALUES (?, ?, ' . $this->db->now() . ')',
                $group_id,
                $contact_id
            );

            if ($error = $this->db->is_error()) {
                $this->set_error(self::ERROR_SAVING, $error);
            } else {
                $added++;
            }
        }

        return $added;
    }

    /**
     * Remove the given contact records from a certain group
     *
     * @param string       $group_id Group identifier
     * @param array|string $ids      List of contact identifiers to be removed
     *
     * @return int Number of deleted group members
     */
    #[Override]
    public function remove_from_group($group_id, $ids)
    {
        if (!is_array($ids)) {
            $ids = explode(self::SEPARATOR, $ids);
        }

        $ids = $this->db->array2list($ids, 'integer');

        $sql_result = $this->db->query(
            'DELETE FROM ' . $this->db->table_name($this->db_groupmembers, true)
            . ' WHERE `contactgroup_id` = ?'
                . " AND `contact_id` IN ({$ids})",
            $group_id
        );

        return $this->db->affected_rows($sql_result);
    }

    /**
     * Check for existing groups with the same name
     *
     * @param string $name Name to check
     *
     * @return string A group name which is unique for the current use
     */
    private function unique_groupname($name)
    {
        $checkname = $name;
        $num = 2;
        $hit = false;

        do {
            $sql_result = $this->db->query(
                'SELECT 1 FROM ' . $this->db->table_name($this->db_groups, true)
                . ' WHERE `del` <> 1'
                    . ' AND `user_id` = ?'
                    . ' AND `name` = ?',
                $this->user_id,
                $checkname);

            // append number to make name unique
            if ($hit = $this->db->fetch_array($sql_result)) {
                $checkname = $name . ' ' . $num++;
            }
        } while ($hit);

        return $checkname;
    }
}
