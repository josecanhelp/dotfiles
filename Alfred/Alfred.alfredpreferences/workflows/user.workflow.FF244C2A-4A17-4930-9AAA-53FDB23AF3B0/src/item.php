<?php

namespace Ramsearch;

class Item
{
    public $title = null;
    public $subtitle = null;
    public $arg = null;

    public function __construct($content, $authorName, $id)
    {
        $this->title = $content;
        $this->subtitle = $authorName;
        $this->arg = $id;
    }
}
