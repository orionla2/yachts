<?php

/* layout.html.twig */
class __TwigTemplate_28b2268dbdd4e0c8fd2d32481035207b6f0ee634e3e95ad6b748ed45ed35100f extends Twig_Template
{
    public function __construct(Twig_Environment $env)
    {
        parent::__construct($env);

        $this->parent = false;

        $this->blocks = array(
            'title' => array($this, 'block_title'),
            'content' => array($this, 'block_content'),
        );
    }

    protected function doDisplay(array $context, array $blocks = array())
    {
        $__internal_71853f111e3710bd82fbf6c57a0f2d57465b3198a763964b029779a37dcf7a61 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_71853f111e3710bd82fbf6c57a0f2d57465b3198a763964b029779a37dcf7a61->enter($__internal_71853f111e3710bd82fbf6c57a0f2d57465b3198a763964b029779a37dcf7a61_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "layout.html.twig"));

        // line 1
        echo "<!DOCTYPE html>
<html>
    <head>
        <title>";
        // line 4
        $this->displayBlock('title', $context, $blocks);
        echo " - My Silex Application</title>

        <link href=\"";
        // line 6
        echo twig_escape_filter($this->env, $this->env->getExtension('Symfony\Bridge\Twig\Extension\AssetExtension')->getAssetUrl("css/main.css"), "html", null, true);
        echo "\" rel=\"stylesheet\" type=\"text/css\" />

        <script type=\"text/javascript\">
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', 'UA-XXXXXXXX-X']);
            _gaq.push(['_trackPageview']);

            (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
        </script>
    </head>
    <body>
        <h1>Orion TEMPLATE!</h1>
        ";
        // line 22
        $this->displayBlock('content', $context, $blocks);
        // line 23
        echo "    </body>
</html>
";
        
        $__internal_71853f111e3710bd82fbf6c57a0f2d57465b3198a763964b029779a37dcf7a61->leave($__internal_71853f111e3710bd82fbf6c57a0f2d57465b3198a763964b029779a37dcf7a61_prof);

    }

    // line 4
    public function block_title($context, array $blocks = array())
    {
        $__internal_a0375ed3a940451820d41d175f5aee689a8863faa684b966594b029775ce762b = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_a0375ed3a940451820d41d175f5aee689a8863faa684b966594b029775ce762b->enter($__internal_a0375ed3a940451820d41d175f5aee689a8863faa684b966594b029775ce762b_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "title"));

        echo "";
        
        $__internal_a0375ed3a940451820d41d175f5aee689a8863faa684b966594b029775ce762b->leave($__internal_a0375ed3a940451820d41d175f5aee689a8863faa684b966594b029775ce762b_prof);

    }

    // line 22
    public function block_content($context, array $blocks = array())
    {
        $__internal_cf56d3db4142c0739c4c3a53a231cf649ba8004f532fecf7541cf82a33c37a68 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_cf56d3db4142c0739c4c3a53a231cf649ba8004f532fecf7541cf82a33c37a68->enter($__internal_cf56d3db4142c0739c4c3a53a231cf649ba8004f532fecf7541cf82a33c37a68_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        
        $__internal_cf56d3db4142c0739c4c3a53a231cf649ba8004f532fecf7541cf82a33c37a68->leave($__internal_cf56d3db4142c0739c4c3a53a231cf649ba8004f532fecf7541cf82a33c37a68_prof);

    }

    public function getTemplateName()
    {
        return "layout.html.twig";
    }

    public function isTraitable()
    {
        return false;
    }

    public function getDebugInfo()
    {
        return array (  76 => 22,  64 => 4,  55 => 23,  53 => 22,  34 => 6,  29 => 4,  24 => 1,);
    }

    /** @deprecated since 1.27 (to be removed in 2.0). Use getSourceContext() instead */
    public function getSource()
    {
        @trigger_error('The '.__METHOD__.' method is deprecated since version 1.27 and will be removed in 2.0. Use getSourceContext() instead.', E_USER_DEPRECATED);

        return $this->getSourceContext()->getCode();
    }

    public function getSourceContext()
    {
        return new Twig_Source("<!DOCTYPE html>
<html>
    <head>
        <title>{% block title '' %} - My Silex Application</title>

        <link href=\"{{ asset('css/main.css') }}\" rel=\"stylesheet\" type=\"text/css\" />

        <script type=\"text/javascript\">
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', 'UA-XXXXXXXX-X']);
            _gaq.push(['_trackPageview']);

            (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
        </script>
    </head>
    <body>
        <h1>Orion TEMPLATE!</h1>
        {% block content %}{% endblock %}
    </body>
</html>
", "layout.html.twig", "/var/www/html/web/templates/layout.html.twig");
    }
}
