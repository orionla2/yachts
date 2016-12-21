<?php

/* main.html.twig */
class __TwigTemplate_7660d22611c05b49306b7a629e0c4a947a5883110a0c03bfe1aa840c2764145d extends Twig_Template
{
    public function __construct(Twig_Environment $env)
    {
        parent::__construct($env);

        // line 1
        $this->parent = $this->loadTemplate("layout.html.twig", "main.html.twig", 1);
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
        $__internal_331f96b0f52ede72026cb0f6f7fe0192ac3d755fcb58a400d2dda8a978c17e87 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_331f96b0f52ede72026cb0f6f7fe0192ac3d755fcb58a400d2dda8a978c17e87->enter($__internal_331f96b0f52ede72026cb0f6f7fe0192ac3d755fcb58a400d2dda8a978c17e87_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "main.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_331f96b0f52ede72026cb0f6f7fe0192ac3d755fcb58a400d2dda8a978c17e87->leave($__internal_331f96b0f52ede72026cb0f6f7fe0192ac3d755fcb58a400d2dda8a978c17e87_prof);

    }

    // line 3
    public function block_content($context, array $blocks = array())
    {
        $__internal_04a494dabc2e449e86bab4f50332260d93bd854da7c6b7a72f1ffd34f5ba2e46 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_04a494dabc2e449e86bab4f50332260d93bd854da7c6b7a72f1ffd34f5ba2e46->enter($__internal_04a494dabc2e449e86bab4f50332260d93bd854da7c6b7a72f1ffd34f5ba2e46_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        // line 4
        echo "    Main controller
    <p>
    ";
        // line 6
        $context['_parent'] = $context;
        $context['_seq'] = twig_ensure_traversable((isset($context["reqObj"]) ? $context["reqObj"] : $this->getContext($context, "reqObj")));
        foreach ($context['_seq'] as $context["key"] => $context["value"]) {
            // line 7
            echo "        <br>
        Key : ";
            // line 8
            echo twig_escape_filter($this->env, $context["key"], "html", null, true);
            echo "
        <br><br>
        Value : ";
            // line 10
            echo twig_escape_filter($this->env, twig_var_dump($this->env, $context, $context["value"]), "html", null, true);
            echo " <br>
    ";
        }
        $_parent = $context['_parent'];
        unset($context['_seq'], $context['_iterated'], $context['key'], $context['value'], $context['_parent'], $context['loop']);
        $context = array_intersect_key($context, $_parent) + $_parent;
        
        $__internal_04a494dabc2e449e86bab4f50332260d93bd854da7c6b7a72f1ffd34f5ba2e46->leave($__internal_04a494dabc2e449e86bab4f50332260d93bd854da7c6b7a72f1ffd34f5ba2e46_prof);

    }

    public function getTemplateName()
    {
        return "main.html.twig";
    }

    public function isTraitable()
    {
        return false;
    }

    public function getDebugInfo()
    {
        return array (  56 => 10,  51 => 8,  48 => 7,  44 => 6,  40 => 4,  34 => 3,  11 => 1,);
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
    Main controller
    <p>
    {% for key,value in reqObj %}
        <br>
        Key : {{ key }}
        <br><br>
        Value : {{ dump(value) }} <br>
    {% endfor %}
{% endblock %}
", "main.html.twig", "/var/www/html/web/templates/main.html.twig");
    }
}
