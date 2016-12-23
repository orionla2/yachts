<?php

/* index.html.twig */
class __TwigTemplate_54972eb062c5a8bab711e6ad1ad6066608ebad1b2ba14a2506e308cd65833eea extends Twig_Template
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
        $__internal_07520b374330161dcdb961debaff25460cb4e7d9ba6c9f7843ee1e5540fb89a3 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_07520b374330161dcdb961debaff25460cb4e7d9ba6c9f7843ee1e5540fb89a3->enter($__internal_07520b374330161dcdb961debaff25460cb4e7d9ba6c9f7843ee1e5540fb89a3_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "index.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_07520b374330161dcdb961debaff25460cb4e7d9ba6c9f7843ee1e5540fb89a3->leave($__internal_07520b374330161dcdb961debaff25460cb4e7d9ba6c9f7843ee1e5540fb89a3_prof);

    }

    // line 2
    public function block_content($context, array $blocks = array())
    {
        $__internal_9e8214f8146039887fa9cd969e050d0e48fee898ca38013d96c0c41673a1488c = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_9e8214f8146039887fa9cd969e050d0e48fee898ca38013d96c0c41673a1488c->enter($__internal_9e8214f8146039887fa9cd969e050d0e48fee898ca38013d96c0c41673a1488c_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        // line 3
        echo "    Main controller
    <p>
    ";
        // line 5
        $context['_parent'] = $context;
        $context['_seq'] = twig_ensure_traversable((isset($context["reqObj"]) ? $context["reqObj"] : $this->getContext($context, "reqObj")));
        foreach ($context['_seq'] as $context["key"] => $context["value"]) {
            // line 6
            echo "        <br>
        Key : ";
            // line 7
            echo twig_escape_filter($this->env, $context["key"], "html", null, true);
            echo "
        <br><br>
        Value : ";
            // line 9
            echo twig_escape_filter($this->env, twig_var_dump($this->env, $context, $context["value"]), "html", null, true);
            echo " <br>
    ";
        }
        $_parent = $context['_parent'];
        unset($context['_seq'], $context['_iterated'], $context['key'], $context['value'], $context['_parent'], $context['loop']);
        $context = array_intersect_key($context, $_parent) + $_parent;
        
        $__internal_9e8214f8146039887fa9cd969e050d0e48fee898ca38013d96c0c41673a1488c->leave($__internal_9e8214f8146039887fa9cd969e050d0e48fee898ca38013d96c0c41673a1488c_prof);

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
        return array (  56 => 9,  51 => 7,  48 => 6,  44 => 5,  40 => 3,  34 => 2,  11 => 1,);
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
", "index.html.twig", "/var/www/html/web/modules/main/views/main/index.html.twig");
    }
}
