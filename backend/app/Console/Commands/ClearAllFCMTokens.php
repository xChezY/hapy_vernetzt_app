<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\FCMToken;

class ClearAllFCMTokens extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:clear-tokens';


    /**
     * This command clears all FCM tokens from the database.
     *
     * @var string
     */
    protected $description = 'This command clears all FCM tokens from the database.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        FCMToken::truncate();
        $this->info('All tokens were deleted');
    }
}
