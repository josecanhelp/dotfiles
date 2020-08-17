<?php

require_once __DIR__ . '/vendor/autoload.php';

use MeiliSearch\Client;
use Ramsearch\Item;

$searchQuery = $argv[1];
$token = getenv('token');

if (! $token) {
  echo json_encode(['items' => [new Item('No Master Key set', 'Use the ramkey to set the master key', null)]]);
  return;
}

$client = new Client('http://ram.tighten.co:7700', $token);

$index = $client->getIndex('entries');
$result = $index->search($searchQuery);

$alfredItems = [];
foreach ($result['hits'] as $entry) {
  $alfredItems[] = new Item($entry['content'], $entry['author'], $entry['id']);
}

if (empty($alfredItems)) {
  echo json_encode(['items' => [new Item('No matching results found', 'Try a different seach query', null)]]);
  return;
}

print_r(json_encode(['items' => $alfredItems]));
