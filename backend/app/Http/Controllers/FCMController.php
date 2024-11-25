<?php

namespace App\Http\Controllers;

use App\Models\FCMToken;
use Illuminate\Http\Request;
use Kreait\Firebase\Exception\Auth\FailedToVerifyToken;
use Kreait\Firebase\Factory;

class FCMController extends Controller
{
    public function sendDeviceToken(Request $request){

        $auth = (new Factory)->withServiceAccount(base_path() . '/hapy-vernetzt-firebase-adminsdk-leon.json')->createAuth();

        $request->validate([
            'token' => 'required|string'
        ]);
    
        if(!FCMToken::where('token', $request->token)->exists()){
            $fcmtoken = new FCMToken([
                'token' => $request->token
            ]);
            try{
                $auth->verifyIdToken($fcmtoken);
                $fcmtoken->save();
            }catch(FailedToVerifyToken $e){
                return response()->json(['message' => 'Invalid token: '.$e->getMessage()]);
            }
        }
        return response()->json(['message' => 'Device token updated successfully']);
    }
}
