<?php

/* index.html.twig */
class __TwigTemplate_3b3966913b0540e614efe4cb1d1202c0d1df48994a1cab2a30427dee5968e144 extends Twig_Template
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
        $__internal_75b1cb0eb7135c56802e5317c17172058aa41645c3bb1796023526a0c5f2ea11 = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_75b1cb0eb7135c56802e5317c17172058aa41645c3bb1796023526a0c5f2ea11->enter($__internal_75b1cb0eb7135c56802e5317c17172058aa41645c3bb1796023526a0c5f2ea11_prof = new Twig_Profiler_Profile($this->getTemplateName(), "template", "index.html.twig"));

        $this->parent->display($context, array_merge($this->blocks, $blocks));
        
        $__internal_75b1cb0eb7135c56802e5317c17172058aa41645c3bb1796023526a0c5f2ea11->leave($__internal_75b1cb0eb7135c56802e5317c17172058aa41645c3bb1796023526a0c5f2ea11_prof);

    }

    // line 2
    public function block_content($context, array $blocks = array())
    {
        $__internal_7eb171a5aba51e1d00048de3a91ce3b9eef5d86e4a61f03347cf4c252c73a0ca = $this->env->getExtension("Symfony\\Bridge\\Twig\\Extension\\ProfilerExtension");
        $__internal_7eb171a5aba51e1d00048de3a91ce3b9eef5d86e4a61f03347cf4c252c73a0ca->enter($__internal_7eb171a5aba51e1d00048de3a91ce3b9eef5d86e4a61f03347cf4c252c73a0ca_prof = new Twig_Profiler_Profile($this->getTemplateName(), "block", "content"));

        // line 3
        echo "    Welcome to your new Silex Application! OLD DIR.
";
        
        $__internal_7eb171a5aba51e1d00048de3a91ce3b9eef5d86e4a61f03347cf4c252c73a0ca->leave($__internal_7eb171a5aba51e1d00048de3a91ce3b9eef5d86e4a61f03347cf4c252c73a0ca_prof);

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
        return array (  40 => 3,  34 => 2,  11 => 1,);
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
    Welcome to your new Silex Application! OLD DIR.
{% endblock %}
", "index.html.twig", "/var/www/html/web/templates/index.html.twig");
    }
}
