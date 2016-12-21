<?php

/* layout.html.twig */
class __TwigTemplate_dd6926ce79985ebc4cbc0b7c77a8b34d5d900886250155a49dee51f8d411613c extends Twig_Template
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
        $__internal_88bea39bbe63c9f6f05e6e52c297ceb233fd9c435fe3a62c92e184f85322ed5d = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_88bea39bbe63c9f6f05e6e52c297ceb233fd9c435fe3a62c92e184f85322ed5d->enter($__internal_88bea39bbe63c9f6f05e6e52c297ceb233fd9c435fe3a62c92e184f85322ed5d_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "layout.html.twig"));

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
        ";
        // line 21
        $this->displayBlock('content', $context, $blocks);
        // line 22
        echo "    </body>
</html>
";
        
        $__internal_88bea39bbe63c9f6f05e6e52c297ceb233fd9c435fe3a62c92e184f85322ed5d->leave($__internal_88bea39bbe63c9f6f05e6e52c297ceb233fd9c435fe3a62c92e184f85322ed5d_prof);

    }

    // line 4
    public function block_title($context, array $blocks = array())
    {
        $__internal_b06872d0ceef302e4353865637da6a46c95608b4ca53942c9377ec2eaee005b7 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_b06872d0ceef302e4353865637da6a46c95608b4ca53942c9377ec2eaee005b7->enter($__internal_b06872d0ceef302e4353865637da6a46c95608b4ca53942c9377ec2eaee005b7_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "title"));

        echo "";
        
        $__internal_b06872d0ceef302e4353865637da6a46c95608b4ca53942c9377ec2eaee005b7->leave($__internal_b06872d0ceef302e4353865637da6a46c95608b4ca53942c9377ec2eaee005b7_prof);

    }

    // line 21
    public function block_content($context, array $blocks = array())
    {
        $__internal_ae7e153ffb9e09b47395d63c8409022d4786999ce62b6a635b9204d76f24be9b = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_ae7e153ffb9e09b47395d63c8409022d4786999ce62b6a635b9204d76f24be9b->enter($__internal_ae7e153ffb9e09b47395d63c8409022d4786999ce62b6a635b9204d76f24be9b_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        
        $__internal_ae7e153ffb9e09b47395d63c8409022d4786999ce62b6a635b9204d76f24be9b->leave($__internal_ae7e153ffb9e09b47395d63c8409022d4786999ce62b6a635b9204d76f24be9b_prof);

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
        return array (  75 => 21,  63 => 4,  54 => 22,  52 => 21,  34 => 6,  29 => 4,  24 => 1,);
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
        {% block content %}{% endblock %}
    </body>
</html>
", "layout.html.twig", "/var/www/html/web/templates/layout.html.twig");
    }
}
