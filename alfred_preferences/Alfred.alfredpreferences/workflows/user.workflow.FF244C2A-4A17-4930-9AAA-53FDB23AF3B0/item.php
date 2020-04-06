<?php

/*
 * This file is part of the alfred-github-workflow package.
 *
 * (c) Gregor Harlan
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

class Item
{
    public $title = null;
    public $subtitle = null;
    public $arg = null;

    public function __construct($apiItem)
    {
        $this->title = $apiItem->content;
        $this->subtitle = $apiItem->author->name;
        $this->arg = $apiItem->id;
    }
}
