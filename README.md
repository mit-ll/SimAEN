# CDC-ct-workflow-modeling
## Disclaimer

DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited. This material is based
upon work supported by the Under Secretary of Defense for Research and Engineering under Air Force
ContractNo. FA8702-15-D-0001. Any opinions, findings, conclusions or recommendations expressed in this
material are those of the author(s) and do not necessarily reflect the views of the Under Secretary of
Defense for Research and Engineering.© 2020 Massachusetts Institute of Technology

Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013 or 7014
(Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work are defined by DFARS
252.227-7013 or DFARS252.227-7014 as detailed above. Use of this work other than as specifically
authorized by the U.S. Government may violate any copyrights that exist in this work.



~~~~
The core functionality of this package is contained in src/WorkflowModel.py. Running this program directly
through python will produce summary statistics along with the json data files that contain all of the
information about the run. Matlab wrapper code is also included to facilitate easy change of configuration
settings and enhanced visualization capabilities.

All of the base configuration settings are in src/pytools/config.txt. This file uses the convention that
comments are designated by a ‘#’ and configuration parameters and values are of the format parameter = value.
These can be changed directly in the file, but can also be specified in run.m when executing from Matlab. To
specify deviations from the values in config.txt, run.m can be updated using the convention
setup.<parameter> = <value>; in the section “Deviate from default, if desired”
  
Running the application through Matlab is done by running run.m while in the base directory. The base
directory also needs to be added to the Matlab path. Once the run is complete functions such as basicPlot.m
and prettyPlot.m are used to explore the values produced by the run. Additional visualization and analytic
tools will use the results stored in the variable arraysOut. This contains several types of information
including the dispensation of each of the individuals in the simulation as well pre-summarized information
pertaining to a wide range of interesting metrics.

The individual status’ stored in arraysOut.arrays.ISM are coded according to the specification in
process_logs.py. Each of these two character codes define the behavior and state of the individual on each
day. The first digit is:

0 – Normal behavior

1 – Minimal restriction

2 – Moderate restriction

3 – Maximal restriction


And the second digit is:

1 – Exposed

2 – Pre-symptomatic

3 – Symptomatic

4 – Asymptomatic

5 – Uninfected

6 – Recovered


The other information is contained in arraysOut.arrays.days and arraysOut.arrays.people. The ‘days’ array summarizes each day with a count of each event of interest. The ‘people’ array provides all of the pertinent information about each person, such as which individual generated them and whether or not they were ever tested.
