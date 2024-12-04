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
    
        if(!FCMToken::where('token', $request->token)->exists()){
            $fcmtoken = new FCMToken([
                'token' => $request->token
            ]);
            $fcmtoken->save();
        }
        return response()->json(['message' => 'Device token updated successfully']);
    }

    public function sendMessage(Request $request) {

        $factory = (new Factory)->withServiceAccount(base_path() . '/hapy-vernetzt-app-firebase-adminsdk.json');

        $messaging = $factory->createMessaging();
        $tokens = FCMToken::getAllTokens();
        $message = CloudMessage::new();
        $messaging->sendMulticast($message, $tokens);

        return response()->json(['message' => 'Messages sent successfully']);
    }

}
