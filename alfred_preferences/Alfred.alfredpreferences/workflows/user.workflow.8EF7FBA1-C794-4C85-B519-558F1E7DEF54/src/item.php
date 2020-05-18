<?php

namespace RegistrarLookup;

class Item
{
    public $title = null;
    public $subtitle = null;
    public $arg = null;

    public function __construct($title, $subtitle, $arg)
    {
        $this->title = $title;
        $this->subtitle = $subtitle;
        $this->arg = $arg;
    }
}
