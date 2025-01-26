<?php

use App\Http\Controllers\FCMController;

$apitoken = app()->config->get('app.schedule');

if ($apitoken == "MINUTE") {
    Schedule::call(function () {
        $controller = new FCMController();
        $controller->sendMessage();
    })->everyMinute();
} else if ($apitoken == "15MINUTES") {
    Schedule::call(function () {
        $controller = new FCMController();
        $controller->sendMessage();
    })->every15Minutes();
} else if ($apitoken == "HOUR") {
    Schedule::call(function () {
        $controller = new FCMController();
        $controller->sendMessage();
    })->everyHour();
} else if ($apitoken == "DAY") {
    Schedule::call(function () {
        $controller = new FCMController();
        $controller->sendMessage();
    })->everyDay();
}


