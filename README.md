
<br/>

### ohdsilab: Tools for using Roux OHDSI Lab at Northeastern University

<hr/>
<!-- badges: start -->
<!-- badges: end -->

The goals of the ohdsilab R package are two fold: 

1. Streamline working with the OHDSI-Lab database at the Roux Institute (and other OMOP CDM databases)

2. Provide an easier on-ramp for students and researchers new to working with the OMOP CDM or SQL 
databases. 

The package contains functions and template code snippets to facilitate easier use
of the Ohdsilab. These functions and snippits build on existing OHDSI R packages like
{DatabaseConnector} as well as standard R packages like {dplyr} and {tidyr}. The package also contains
a number of vingettes intended for R users who are new to OHDSI-Lab, the OMOP CDM, or working with 
data in SQL databases from R. 

If you're a new ohdsilab user, you can get set up by [following the user guide](https://northeastern.sharepoint.com/:f:/r/sites/OHDSINortheastern/Shared%20Documents/OHDSI%20Lab%20-%20User%20Group?csf=1&web=1&e=lvfisr). 

After you've created your workspace and have successfully logged in, finish setting
up your R environment by [completing the setup tutorial](https://roux-ohdsi.github.io/ohdsilab/articles/01-intro-to-ohdsilab.html)

If you have questions about using ohdsilab or getting started, 
[the OHDSI center hosts weekly office hours](https://outlook.office.com/bookwithme/user/3164c5734afa47c2be308b599b41631a@northeastern.edu/meetingtype/SVRwCe7HMUGxuT6WGxi68g2?anonymous&ep=mcard).

<br> 

#### An important note on storage

Your OHDSI Lab Workspace is intended to be a resource for *compute*. ***It is NOT intended to be permanent storage***.
We do not recommend saving scripts permanently on your workspace without backing them up elsewhere.

The best practice is to use a version control system for saving code and results
to a location other than your workspace. We recommend using git and github for this purpose. 
Storage on your workspace should be considered temporary and not a location for long-term
storage. 

Thankfully, connecting git and github to R is now quite easy. Follow the steps in 
[Happy Git with R](https://happygitwithr.com/https-pat) chapter 9 to connect your
github account to RStudio. And while using git and github can be complex, for a single
user (you!), it's as simple as knowing these four commands: 

```
git pull
git add .
git commit -m "this is a message about the changes you made"
git push
```

Information about these commands can be found in [Happy Git with R](https://happygitwithr.com/git-commands) chapter 21. Or, for a visual explanation, see the [fantastic illustrations by Allison Horst](https://allisonhorst.com/git-github).
