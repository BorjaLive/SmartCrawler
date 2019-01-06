<?php
if(empty($_GET["user"]) or empty($_GET["num"]) or empty($_GET["start"]) or empty($_GET["params"])){
	echo "PARAM ERROR";
	die();
}

echo getJsonUser($_GET["user"],$_GET["num"],$_GET["start"],$_GET["params"]);
                    
function getJsonUser($user,$num_tweets,$starter,$params){
        ini_set('display_errors', 1);
        require_once('TwitterAPIExchange.php');
 
        $settings = array(	//¿Buscas mi API KEY? Ve a robarla al servidor, no está aquí.
            'consumer_key' => "", 
            'consumer_secret' => "",
            'oauth_access_token' => "",
            'oauth_access_token_secret' => ""
        );
       
        $url = 'https://api.twitter.com/1.1/statuses/user_timeline.json';
		$params = str_replace("[","&",$params);
        $getfield = '?screen_name='.$user.'&count='.$num_tweets.($starter=="START"?"":'&max_id='.$starter).($params=="NONE"?"":$params);
 
        $requestMethod = 'GET';
        $twitter = new TwitterAPIExchange($settings);
        $json =  $twitter->setGetfield($getfield)
                     ->buildOauth($url, $requestMethod)
                     ->performRequest();
        return $json;
}
?>