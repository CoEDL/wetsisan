# How to add a new page to the documentation

This folder contains the basic information to add a new page to the documentation.

The documentation is built using Jekyll and the [Minimal Mistakes theme](https://mmistakes.github.io/minimal-mistakes/docs/quick-start-guide/). The theme documentation is a good place to look for info.

## To modify an existing page

1. All the existing pages are found in the `/docs/_pages/` directory of the project. One .md file corresponds to one page.

2. Modification can be done by cloning the repository and changing the files locally (and then pushing any changes to the repository), or directly in the web browser using the Github editing tools

## To create a new page

1. Copy and paste the `sample_page.md` file into the `/docs/_pages/` directory

2. Change the name of the file to be meaningful !!

3. Edit the page information in the YAML front matter (the first lines on the code, surrounded by `---`). It is especially important to change the permalink of the page (which will define its url)

4. Edit the page content in the file (the sample page contains simple syntax examples)

5. Once the page is ready, make sure there are links to it from other pages (in the form of `[link](/IRL/your_permalink_goes_here/)`)

6. If you want to add the page to the navigation bar on the left, make sure a link to it is added in the `_data/navigation.yml` file, which defines the navigation bar links.