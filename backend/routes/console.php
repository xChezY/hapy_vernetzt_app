<?php

use App\Http\Controllers\FCMController;

Schedule::call(function () {
    $controller = new FCMController();
    $controller->sendMessage();
})->everyMinute();