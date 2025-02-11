<?php

use App\Http\Controllers\FCMController;
use Illuminate\Support\Facades\Schedule;

$schedule_interval = app()->config->get('app.schedule');

$function  = function () {
    (new FCMController())->sendMessage();
};

if ( $schedule_interval == "MINUTE") {
    Schedule::call( $function )->everyMinute();
} else if ( $schedule_interval == "15MINUTES") {
    Schedule::call( $function )->everyFifteenMinutes();
} else if ( $schedule_interval == "HOUR") {
    Schedule::call( $function )->hourly();
} else if ( $schedule_interval == "DAY") {
    Schedule::call( $function )->daily();
}


