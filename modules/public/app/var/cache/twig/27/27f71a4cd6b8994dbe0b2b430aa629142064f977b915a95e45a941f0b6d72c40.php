<?php

/* index.html.twig */
class __TwigTemplate_f30c2feb9cda34cf9e941bef0145a38aaf9d7e2147e529b2ef4fb25fccf838f4 extends Twig_Template
{
    public function __construct(Twig_Environment $env)
    {
        parent::__construct($env);

        // line 1
        $this->parent = $this->loadTemplate("layout.html.twig", "index.html.twig", 1);
        $this->blocks = array(
            'content' => array($this, 'block_content'),
        );
    }

    protected function doGetParent(array $context)
    {
        return "layout.html.twig";
    }

    protected function doDisplay(array $context, array $blocks = array())
    {
        $__internal_b4c867e496d87e60d0dd2b5df8725e2a227fc38d90d9e219d3979a39d08c1f01 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_b4c867e496d87e60d0dd2b5df8725e2a227fc38d90d9e219d3979a39d08c1f01->enter($__internal_b4c867e496d87e60d0dd2b5df8725e2a227fc38d90d9e219d3979a39d08c1f01_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "index.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_b4c867e496d87e60d0dd2b5df8725e2a227fc38d90d9e219d3979a39d08c1f01->leave($__internal_b4c867e496d87e60d0dd2b5df8725e2a227fc38d90d9e219d3979a39d08c1f01_prof);

    }

    // line 3
    public function block_content($context, array $blocks = array())
    {
        $__internal_48c87c3549fb520dc931f58fa5fab7c256a0a1a677d7cabf699838c53a371bc5 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_48c87c3549fb520dc931f58fa5fab7c256a0a1a677d7cabf699838c53a371bc5->enter($__internal_48c87c3549fb520dc931f58fa5fab7c256a0a1a677d7cabf699838c53a371bc5_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        // line 4
        echo "    Welcome to your new Silex Application!
";
        
        $__internal_48c87c3549fb520dc931f58fa5fab7c256a0a1a677d7cabf699838c53a371bc5->leave($__internal_48c87c3549fb520dc931f58fa5fab7c256a0a1a677d7cabf699838c53a371bc5_prof);

    }

    public function getTemplateName()
    {
        return "index.html.twig";
    }

    public function isTraitable()
    {
        return false;
    }

    public function getDebugInfo()
    {
        return array (  40 => 4,  34 => 3,  11 => 1,);
    }

    /** @deprecated since 1.27 (to be removed in 2.0). Use getSourceContext() instead */
    public function getSource()
    {
        @trigger_error('The '.__METHOD__.' method is deprecated since version 1.27 and will be removed in 2.0. Use getSourceContext() instead.', E_USER_DEPRECATED);

        return $this->getSourceContext()->getCode();
    }

    public function getSourceContext()
    {
        return new Twig_Source("{% extends \"layout.html.twig\" %}

{% block content %}
    Welcome to your new Silex Application!
{% endblock %}
", "index.html.twig", "/var/www/html/web/templates/index.html.twig");
    }
}
