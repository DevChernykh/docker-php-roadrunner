<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;

class DashboardController extends AbstractController
{
    public function __invoke(): Response
    {
        return new Response('<h1>Welcome to Dashboard!</h1>');
    }
}
