<?php
if(empty($_GET["user"]) or empty($_GET["num"]) or empty($_GET["start"])){
	echo "PARAM ERROR";
	die();
}

echo getJsonUser($_GET["user"],$_GET["num"],$_GET["start"]);
                    
function getJsonUser($user,$num_tweets,$starter){
        ini_set('display_errors', 1);
        require_once('TwitterAPIExchange.php');
 
        /** Set access tokens here - see: https://dev.twitter.com/apps/ **/
        $settings = array(
            'consumer_key' => "LjFhoU32yQx3aScxwFWGT1rDU",
            'consumer_secret' => "ZSMBtH2aG8nQeVNLYqr5vWD8ZOVNVbp2OYWGeiKlYNPIyXNIec",
            'oauth_access_token' => "1491086923-9CPIaHKifoD6bbNR4bujdBIkHIFvOQDW7Mv2FuM",
            'oauth_access_token_secret' => "fXbSIASe9oXWT1x5c8C3XLLSFvBToz2Iqv7tYxGxYizcS"
        );
       
        $url = 'https://api.twitter.com/1.1/statuses/user_timeline.json';
        $getfield = '?screen_name='.$user.'&count='.$num_tweets.($starter=="START"?"":'&max_id='.$starter).'&exclude_replies=true';
 
        $requestMethod = 'GET';
        $twitter = new TwitterAPIExchange($settings);
        $json =  $twitter->setGetfield($getfield)
                     ->buildOauth($url, $requestMethod)
                     ->performRequest();
        return $json;
}
?>