<?php

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude('var')
;

return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS2.0' => true,
    ])
    ->setCacheFile('var/cache/.php-cs-fixer')
    ->setFinder($finder)
;
