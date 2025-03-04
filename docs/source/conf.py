# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))


# -- Project information -----------------------------------------------------

project = "54gene-wgs-germline"
copyright = "2022, B. Ballew, E. Joshi, L. Auriga, 54gene"
author = "Bari Jane Ballew, Esha Joshi, Lightning Auriga"
version = "1.0.0"

# -- General configuration ---------------------------------------------------

# Autosection feature extension to allow reference sections using their title
extensions = ["sphinx.ext.autosectionlabel", "myst_parser"]
autosectionlabel_prefix_document = True

# Add any paths that contain templates here, relative to this directory.
templates_path = ["_templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["_static"]

# Path to custom.css style sheet with 54gene branding
html_css_files = ["custom.css"]

# Path to the 54gene logo displayed on the left hand static panel
html_logo = "images/54gene_logo.png"
