<?php

/* @WebProfiler/Collector/router.html.twig */
class __TwigTemplate_9b39140914be0880899f4097403571774d4a143dfe6a9c76e31b7a3b67da7b50 extends Twig_Template
{
    public function __construct(Twig_Environment $env)
    {
        parent::__construct($env);

        // line 1
        $this->parent = $this->loadTemplate("@WebProfiler/Profiler/layout.html.twig", "@WebProfiler/Collector/router.html.twig", 1);
        $this->blocks = array(
            'toolbar' => array($this, 'block_toolbar'),
            'menu' => array($this, 'block_menu'),
            'panel' => array($this, 'block_panel'),
        );
    }

    protected function doGetParent(array $context)
    {
        return "@WebProfiler/Profiler/layout.html.twig";
    }

    protected function doDisplay(array $context, array $blocks = array())
    {
        $__internal_905a7438cfdcc97e04973a6941f90535cd5cf2b5ad5c6832ec35c49bab806d4b = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_905a7438cfdcc97e04973a6941f90535cd5cf2b5ad5c6832ec35c49bab806d4b->enter($__internal_905a7438cfdcc97e04973a6941f90535cd5cf2b5ad5c6832ec35c49bab806d4b_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "@WebProfiler/Collector/router.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_905a7438cfdcc97e04973a6941f90535cd5cf2b5ad5c6832ec35c49bab806d4b->leave($__internal_905a7438cfdcc97e04973a6941f90535cd5cf2b5ad5c6832ec35c49bab806d4b_prof);

    }

    // line 3
    public function block_toolbar($context, array $blocks = array())
    {
        $__internal_fba254ac7b8e0cf17906ebc8b7d7b4b5d67611b54e3c2b81068f09ddaf7d9d6b = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_fba254ac7b8e0cf17906ebc8b7d7b4b5d67611b54e3c2b81068f09ddaf7d9d6b->enter($__internal_fba254ac7b8e0cf17906ebc8b7d7b4b5d67611b54e3c2b81068f09ddaf7d9d6b_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "toolbar"));

        
        $__internal_fba254ac7b8e0cf17906ebc8b7d7b4b5d67611b54e3c2b81068f09ddaf7d9d6b->leave($__internal_fba254ac7b8e0cf17906ebc8b7d7b4b5d67611b54e3c2b81068f09ddaf7d9d6b_prof);

    }

    // line 5
    public function block_menu($context, array $blocks = array())
    {
        $__internal_079505fe89b7056252c4215778fe0b295db87fcce08d00542699fe93b406cddf = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_079505fe89b7056252c4215778fe0b295db87fcce08d00542699fe93b406cddf->enter($__internal_079505fe89b7056252c4215778fe0b295db87fcce08d00542699fe93b406cddf_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "menu"));

        // line 6
        echo "<span class=\"label\">
    <span class=\"icon\">";
        // line 7
        echo twig_include($this->env, $context, "@WebProfiler/Icon/router.svg");
        echo "</span>
    <strong>Routing</strong>
</span>
";
        
        $__internal_079505fe89b7056252c4215778fe0b295db87fcce08d00542699fe93b406cddf->leave($__internal_079505fe89b7056252c4215778fe0b295db87fcce08d00542699fe93b406cddf_prof);

    }

    // line 12
    public function block_panel($context, array $blocks = array())
    {
        $__internal_1a3189511296b520613e9aec99bf16f35bc105ecb4fef71c55273c1a8bf54595 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_1a3189511296b520613e9aec99bf16f35bc105ecb4fef71c55273c1a8bf54595->enter($__internal_1a3189511296b520613e9aec99bf16f35bc105ecb4fef71c55273c1a8bf54595_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "panel"));

        // line 13
        echo "    ";
        echo $this->env->getExtension('Symfony\Bridge\Twig\Extension\HttpKernelExtension')->renderFragment($this->env->getExtension('Symfony\Bridge\Twig\Extension\RoutingExtension')->getPath("_profiler_router", array("token" => (isset($context["token"]) ? $context["token"] : $this->getContext($context, "token")))));
        echo "
";
        
        $__internal_1a3189511296b520613e9aec99bf16f35bc105ecb4fef71c55273c1a8bf54595->leave($__internal_1a3189511296b520613e9aec99bf16f35bc105ecb4fef71c55273c1a8bf54595_prof);

    }

    public function getTemplateName()
    {
        return "@WebProfiler/Collector/router.html.twig";
    }

    public function isTraitable()
    {
        return false;
    }

    public function getDebugInfo()
    {
        return array (  73 => 13,  67 => 12,  56 => 7,  53 => 6,  47 => 5,  36 => 3,  11 => 1,);
    }

    /** @deprecated since 1.27 (to be removed in 2.0). Use getSourceContext() instead */
    public function getSource()
    {
        @trigger_error('The '.__METHOD__.' method is deprecated since version 1.27 and will be removed in 2.0. Use getSourceContext() instead.', E_USER_DEPRECATED);

        return $this->getSourceContext()->getCode();
    }

    public function getSourceContext()
    {
        return new Twig_Source("{% extends '@WebProfiler/Profiler/layout.html.twig' %}

{% block toolbar %}{% endblock %}

{% block menu %}
<span class=\"label\">
    <span class=\"icon\">{{ include('@WebProfiler/Icon/router.svg') }}</span>
    <strong>Routing</strong>
</span>
{% endblock %}

{% block panel %}
    {{ render(path('_profiler_router', { token: token })) }}
{% endblock %}
", "@WebProfiler/Collector/router.html.twig", "/var/www/html/web/vendor/symfony/web-profiler-bundle/Resources/views/Collector/router.html.twig");
    }
}
