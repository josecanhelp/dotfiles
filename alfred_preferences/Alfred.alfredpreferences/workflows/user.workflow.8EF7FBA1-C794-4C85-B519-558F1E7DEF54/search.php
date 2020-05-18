<?php
require_once __DIR__ . '/vendor/autoload.php';

use RegistrarLookup\Item;
use Zttp\Zttp;

class Lookup
{
    public static function getWhoisFor($domain)
    {
        return once(function () use ($domain) {
            return shell_exec("whois {$domain}");
        });
    }

    public static function getRegistrarById($ianaID)
    {
        return once(function () use ($ianaID) {
            $response = Zttp::get('https://www.iana.org/assignments/registrar-ids/registrar-ids.xml');
            $json = json_encode(simplexml_load_string($response));
            $array = json_decode($json, TRUE)['registry']['record'];
            $index = array_search($ianaID, array_column($array, 'value'));
            return trim($array[$index]['name']) ?? null;
        });
    }
}

function extractValueFromLines($lines)
{
    if (! empty($lines)) {
        $tmp = explode(':', array_pop($lines));
        return trim(array_pop($tmp));
    } else {
        return null;
    }
}

$lookupResult = Lookup::getWhoisFor($argv[1]);
$resultArray = preg_split('/\n+/', trim($lookupResult));

$resellerLines = preg_grep("/^Reseller/", $resultArray);
$reseller = extractValueFromLines($resellerLines);

$registrarLines = preg_grep("/^Registrar:/", $resultArray);
$registrar = extractValueFromLines($registrarLines);

// This is a string used in Hover responses, it could work for others
$regServiceProvider = null;
$providerStringLocation = preg_grep("/^Registration Service Provider:/", $resultArray);
if (! empty($providerStringLocation)) {
    $tmp = array_keys($providerStringLocation);
    $regProviderKey = array_pop($tmp);
    $actualProviderStringKey = $regProviderKey + 1;
    $tmp2 = explode(',', trim($resultArray[$actualProviderStringKey]));
    $regServiceProvider = array_shift($tmp2);
}

// Fallback to getting the name of a registrar from the IANA ID
// This uses the list found here: https://www.iana.org/assignments/registrar-ids/registrar-ids.xml
$registrarById = null;
$registrarIdLines = preg_grep("/^Registrar IANA ID:/", $resultArray);
if (! empty($registrarIdLines)) {
    $tmp = explode(':', array_pop($registrarIdLines));
    $registrarId = trim(array_pop($tmp));
    $registrarById = Lookup::getRegistrarById($registrarId);
}

// Ordered by relevance
$filteredResults = array_filter([
    'reseller' => $reseller,
    'regServiceProvider' => $regServiceProvider,
    'registrar' => $registrar,
    'registrarById' => $registrarById,
]);

// Will use later to inform the user how accurate the result may be
$firstKey = array_key_first($filteredResults);

$finalAnswer = array_shift($filteredResults);

print_r(json_encode(['items' => [new Item($finalAnswer ?? 'n/a', $firstKey, $finalAnswer ?? 'n/a' )]]));
