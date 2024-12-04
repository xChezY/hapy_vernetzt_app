<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FCMToken extends Model
{
    use HasFactory;

    public $timestamps = false;
    protected $table = 'fcmtoken';
    protected $fillable = ['token'];

    public static function getAllTokens()
    {
        return self::all()->pluck('token')->toArray();
    }

    public static function removeToken($token)
    {
        return self::where('token', $token)->delete();
    }

    public function toString()
    {
        return $this->token;
    }
}
