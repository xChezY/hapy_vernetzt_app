<?php

namespace App\Http\Controllers;

use App\Models\FCMToken;
use Illuminate\Http\Request;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Factory;

class FCMController extends Controller
{

    public function sendDeviceToken(Request $request){

        $request->validate([
            'token' => 'required|string'
        ]);

        $factory = (new Factory)->withServiceAccount(base_path() . '/hapy-vernetzt-app-firebase-adminsdk.json');
        $messaging = $factory->createMessaging();
    
        if(!FCMToken::where('token', $request->token)->exists()){
            $fcmtoken = new FCMToken([
                'token' => $request->token
            ]);
            $result = $messaging->validateRegistrationTokens($fcmtoken);
            if (!empty($result['valid'])){
                $fcmtoken->save();
                return response()->json(['message' => 'Device token updated successfully']);
            }
        }
        return response()->json(['message' => 'Token is invalid or already exists']);
    }

    public function sendMessage() {
        $factory = (new Factory)->withServiceAccount(base_path() . '/hapy-vernetzt-app-firebase-adminsdk.json');
        $messaging = $factory->createMessaging();
    
        $tokens = FCMToken::getAllTokens();
        $message = CloudMessage::new();
        $report = $messaging->sendMulticast($message, $tokens);

        foreach($report->invalidTokens() as $invalidtoken){
            FCMToken::removeToken($invalidtoken);
        }

        return response()->json(['message' => 'Messages sent successfully']);
    }

}
