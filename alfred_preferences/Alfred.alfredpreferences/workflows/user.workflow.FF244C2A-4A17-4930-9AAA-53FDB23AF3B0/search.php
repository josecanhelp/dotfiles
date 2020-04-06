<?php

namespace Ram;

require 'item.php';

use Item;
use function json_decode;

class Search
{
    public $response = null;
    public $token = 'q9Gku1r9zAKE8IrbIaCHngONTTjHWBMglPStXqEWh7fFlJOrHLoTCLLZsR0qKHnYDjcaGqha4Lf1YNkt';

    public function easyCurl($query)
    {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "https://ram.test/api/search?q={$query}");
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer {$this->token}"]);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Use this for local testing, not for production

        $this->response = curl_exec($ch);

        if (! $this->response) {
            die('Error: "' . curl_error($ch) . '" - Code: ' . curl_errno($ch));
        }

        curl_close($ch);
    }

    public function run($query)
    {
        $this->easyCurl($query);
    }

    public function getJsonItems()
    {
        $responseItems = json_decode($this->response);
        $alfredItems = [];

        foreach ($responseItems as $item) {
            $alfredItems[] = new Item($item);
        }

        return json_encode(['items' => $alfredItems]);
    }
}

$search = new Search;
$search->run($argv[1]);
echo $search->getJsonItems();
