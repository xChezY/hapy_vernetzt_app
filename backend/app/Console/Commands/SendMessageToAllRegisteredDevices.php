<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FCMController;

class SendMessageToAllRegisteredDevices extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:send-message';


    /**
     * This command sends a message to all registered devices.
     *
     * @var string
     */
    protected $description = 'This command sends a message to all registered devices.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $controller = new FCMController();
        $controller->sendMessage();
    }
}
