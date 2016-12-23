<?php

/* @WebProfiler/Collector/exception.html.twig */
class __TwigTemplate_1f0e24842faa3936bd448e8a68a79d092166c4fc254d17d20454017fa3d82ad9 extends Twig_Template
{
    public function __construct(Twig_Environment $env)
    {
        parent::__construct($env);

        // line 1
        $this->parent = $this->loadTemplate("@WebProfiler/Profiler/layout.html.twig", "@WebProfiler/Collector/exception.html.twig", 1);
        $this->blocks = array(
            'head' => array($this, 'block_head'),
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
        $__internal_44d0fa71ec1d12905b62dde084d45635b9f34d51ae8b5f3fedbaa722b5b7b279 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_44d0fa71ec1d12905b62dde084d45635b9f34d51ae8b5f3fedbaa722b5b7b279->enter($__internal_44d0fa71ec1d12905b62dde084d45635b9f34d51ae8b5f3fedbaa722b5b7b279_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "@WebProfiler/Collector/exception.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_44d0fa71ec1d12905b62dde084d45635b9f34d51ae8b5f3fedbaa722b5b7b279->leave($__internal_44d0fa71ec1d12905b62dde084d45635b9f34d51ae8b5f3fedbaa722b5b7b279_prof);

    }

    // line 3
    public function block_head($context, array $blocks = array())
    {
        $__internal_46fa819c78170c7de3e4ed07faebe707c3ba7b344a9d3d12f576cc12c18a7be1 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_46fa819c78170c7de3e4ed07faebe707c3ba7b344a9d3d12f576cc12c18a7be1->enter($__internal_46fa819c78170c7de3e4ed07faebe707c3ba7b344a9d3d12f576cc12c18a7be1_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "head"));

        // line 4
        echo "    ";
        if ($this->getAttribute((isset($context["collector"]) ? $context["collector"] : $this->getContext($context, "collector")), "hasexception", array())) {
            // line 5
            echo "        <style>
            ";
            // line 6
            echo $this->env->getExtension('Symfony\Bridge\Twig\Extension\HttpKernelExtension')->renderFragment($this->env->getExtension('Symfony\Bridge\Twig\Extension\RoutingExtension')->getPath("_profiler_exception_css", array("token" => (isset($context["token"]) ? $context["token"] : $this->getContext($context, "token")))));
            echo "
        </style>
    ";
        }
        // line 9
        echo "    ";
        $this->displayParentBlock("head", $context, $blocks);
        echo "
";
        
        $__internal_46fa819c78170c7de3e4ed07faebe707c3ba7b344a9d3d12f576cc12c18a7be1->leave($__internal_46fa819c78170c7de3e4ed07faebe707c3ba7b344a9d3d12f576cc12c18a7be1_prof);

    }

    // line 12
    public function block_menu($context, array $blocks = array())
    {
        $__internal_4d14789409c71fd79ca3bf8759914a70273adb025df4803304ef4faec4f496b4 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_4d14789409c71fd79ca3bf8759914a70273adb025df4803304ef4faec4f496b4->enter($__internal_4d14789409c71fd79ca3bf8759914a70273adb025df4803304ef4faec4f496b4_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "menu"));

        // line 13
        echo "    <span class=\"label ";
        echo (($this->getAttribute((isset($context["collector"]) ? $context["collector"] : $this->getContext($context, "collector")), "hasexception", array())) ? ("label-status-error") : ("disabled"));
        echo "\">
        <span class=\"icon\">";
        // line 14
        echo twig_include($this->env, $context, "@WebProfiler/Icon/exception.svg");
        echo "</span>
        <strong>Exception</strong>
        ";
        // line 16
        if ($this->getAttribute((isset($context["collector"]) ? $context["collector"] : $this->getContext($context, "collector")), "hasexception", array())) {
            // line 17
            echo "            <span class=\"count\">
                <span>1</span>
            </span>
        ";
        }
        // line 21
        echo "    </span>
";
        
        $__internal_4d14789409c71fd79ca3bf8759914a70273adb025df4803304ef4faec4f496b4->leave($__internal_4d14789409c71fd79ca3bf8759914a70273adb025df4803304ef4faec4f496b4_prof);

    }

    // line 24
    public function block_panel($context, array $blocks = array())
    {
        $__internal_20e5cbaae71c14dae50ed45fd6c872792afc2081efb55f9ad45a012142614ba3 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_20e5cbaae71c14dae50ed45fd6c872792afc2081efb55f9ad45a012142614ba3->enter($__internal_20e5cbaae71c14dae50ed45fd6c872792afc2081efb55f9ad45a012142614ba3_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "panel"));

        // line 25
        echo "    <h2>Exceptions</h2>

    ";
        // line 27
        if ( !$this->getAttribute((isset($context["collector"]) ? $context["collector"] : $this->getContext($context, "collector")), "hasexception", array())) {
            // line 28
            echo "        <div class=\"empty\">
            <p>No exception was thrown and caught during the request.</p>
        </div>
    ";
        } else {
            // line 32
            echo "        <div class=\"sf-reset\">
            ";
            // line 33
            echo $this->env->getExtension('Symfony\Bridge\Twig\Extension\HttpKernelExtension')->renderFragment($this->env->getExtension('Symfony\Bridge\Twig\Extension\RoutingExtension')->getPath("_profiler_exception", array("token" => (isset($context["token"]) ? $context["token"] : $this->getContext($context, "token")))));
            echo "
        </div>
    ";
        }
        
        $__internal_20e5cbaae71c14dae50ed45fd6c872792afc2081efb55f9ad45a012142614ba3->leave($__internal_20e5cbaae71c14dae50ed45fd6c872792afc2081efb55f9ad45a012142614ba3_prof);

    }

    public function getTemplateName()
    {
        return "@WebProfiler/Collector/exception.html.twig";
    }

    public function isTraitable()
    {
        return false;
    }

    public function getDebugInfo()
    {
        return array (  117 => 33,  114 => 32,  108 => 28,  106 => 27,  102 => 25,  96 => 24,  88 => 21,  82 => 17,  80 => 16,  75 => 14,  70 => 13,  64 => 12,  54 => 9,  48 => 6,  45 => 5,  42 => 4,  36 => 3,  11 => 1,);
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

{% block head %}
    {% if collector.hasexception %}
        <style>
            {{ render(path('_profiler_exception_css', { token: token })) }}
        </style>
    {% endif %}
    {{ parent() }}
{% endblock %}

{% block menu %}
    <span class=\"label {{ collector.hasexception ? 'label-status-error' : 'disabled' }}\">
        <span class=\"icon\">{{ include('@WebProfiler/Icon/exception.svg') }}</span>
        <strong>Exception</strong>
        {% if collector.hasexception %}
            <span class=\"count\">
                <span>1</span>
            </span>
        {% endif %}
    </span>
{% endblock %}

{% block panel %}
    <h2>Exceptions</h2>

    {% if not collector.hasexception %}
        <div class=\"empty\">
            <p>No exception was thrown and caught during the request.</p>
        </div>
    {% else %}
        <div class=\"sf-reset\">
            {{ render(path('_profiler_exception', { token: token })) }}
        </div>
    {% endif %}
{% endblock %}
", "@WebProfiler/Collector/exception.html.twig", "/var/www/html/web/vendor/symfony/web-profiler-bundle/Resources/views/Collector/exception.html.twig");
    }
}
