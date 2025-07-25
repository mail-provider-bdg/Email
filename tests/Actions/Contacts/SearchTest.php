<?php

namespace Roundcube\Tests\Actions\Contacts;

use Roundcube\Tests\ActionTestCase;
use Roundcube\Tests\OutputHtmlMock;
use Roundcube\Tests\OutputJsonMock;

/**
 * Test class to test rcmail_action_contacts_search
 */
class SearchTest extends ActionTestCase
{
    /**
     * Test search form request
     */
    public function test_run_search_form()
    {
        $action = new \rcmail_action_contacts_search();
        $output = $this->initOutput(\rcmail_action::MODE_HTTP, 'contacts', 'search');

        $this->assertInstanceOf(\rcmail_action::class, $action);
        $this->assertTrue($action->checks());

        $_GET = ['_form' => 1];

        $this->runAndAssert($action, OutputHtmlMock::E_EXIT);

        $result = $output->getOutput();

        $this->assertSame('contactsearch', $output->template);
        $this->assertSame('', $output->getProperty('pagetitle')); // TODO: there should be a title
        $this->assertTrue(stripos($result, '<!DOCTYPE html>') === 0);
    }

    /**
     * Test search request
     */
    public function test_run_quick_search()
    {
        $action = new \rcmail_action_contacts_search();
        $output = $this->initOutput(\rcmail_action::MODE_AJAX, 'contacts', 'search');

        $this->assertTrue($action->checks());

        self::initDB('contacts');

        $_GET = ['_q' => 'George'];

        $this->runAndAssert($action, OutputJsonMock::E_EXIT);

        $result = $output->getOutput();

        $this->assertContains('Content-Type: application/json; charset=UTF-8', $output->headers);
        $this->assertSame('search', $result['action']);
        $this->assertSame(1, $result['env']['pagecount']);
        $this->assertMatchesRegularExpression('/^[0-9a-z]{32}$/', $result['env']['search_request']);
        $this->assertTrue(strpos($result['exec'], 'this.add_contact_row') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.set_rowcount("Contacts 1 to 1 of 1");') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.display_message("1 contacts found.","confirmation",0);') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.unselect_directory();') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.enable_command("search-create",true);') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.update_group_commands()') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.list_contacts_clear();') === false);
    }

    /**
     * Test search request
     */
    public function test_run_search()
    {
        $action = new \rcmail_action_contacts_search();
        $output = $this->initOutput(\rcmail_action::MODE_AJAX, 'contacts', 'search');

        $this->assertTrue($action->checks());

        self::initDB('contacts');

        $_POST = ['_adv' => '1', '_search_organization' => 'acme'];

        $this->runAndAssert($action, OutputJsonMock::E_EXIT);

        $result = $output->getOutput();

        $this->assertContains('Content-Type: application/json; charset=UTF-8', $output->headers);
        $this->assertSame('search', $result['action']);
        $this->assertSame(1, $result['env']['pagecount']);
        $this->assertMatchesRegularExpression('/^[0-9a-z]{32}$/', $result['env']['search_request']);
        $this->assertTrue(strpos($result['exec'], 'this.add_contact_row') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.set_rowcount("Contacts 1 to 1 of 1");') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.display_message("1 contacts found.","confirmation",0);') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.unselect_directory();') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.enable_command("search-create",true);') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.update_group_commands()') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.list_contacts_clear();') !== false);
    }

    /**
     * Test saved search
     */
    public function test_run_saved_search()
    {
        $action = new \rcmail_action_contacts_search();
        $output = $this->initOutput(\rcmail_action::MODE_AJAX, 'contacts', 'search');

        $this->assertTrue($action->checks());

        self::initDB('searches');

        $db = \rcmail::get_instance()->get_dbh();
        $query = $db->query('SELECT * FROM `searches` WHERE `name` = \'test\'');
        $result = $db->fetch_assoc($query);
        $sid = $result['search_id'];

        self::initDB('contacts');

        $_GET = ['_sid' => $sid];

        $this->runAndAssert($action, OutputJsonMock::E_EXIT);

        $result = $output->getOutput();

        $this->assertContains('Content-Type: application/json; charset=UTF-8', $output->headers);
        $this->assertSame('search', $result['action']);
        $this->assertSame(1, $result['env']['pagecount']);
        $this->assertMatchesRegularExpression('/^[0-9a-z]{32}$/', $result['env']['search_request']);
        $this->assertTrue(strpos($result['exec'], 'this.add_contact_row') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.set_rowcount("Contacts 1 to 1 of 1");') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.display_message("1 contacts found.","confirmation",0);') !== false);
        $this->assertTrue(strpos($result['exec'], 'this.unselect_directory();') === false);
        $this->assertTrue(strpos($result['exec'], 'this.enable_command("search-create",true);') === false);
        $this->assertTrue(strpos($result['exec'], 'this.update_group_commands()') !== false);
    }
}
