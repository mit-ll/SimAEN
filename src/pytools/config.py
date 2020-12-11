# Copyright (c) 2020 Massachusetts Institute of Technology
# DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

# This material is based upon work supported under Air Force Contract No. FA8702-15-D-0001.
# Any opinions,findings, conclusions or recommendations expressed in this material are those
# of the author(s) and do not necessarily reflect the views of the Centers for Disease Control.

# (c) 2020 Massachusetts Institute of Technology.

# The software/firmware is provided to you on an As-Is basis

# Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013
# or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work
# are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work
# other than as specifically authorized by the U.S. Government may violate any copyrights that
# exist in this work.

# SPDX short identifier: MIT

#Developed as part of: SimAEN, 2020
#Authors: DI25756, JO26228, ED22162
"""
Tools to work with simulation configuration
"""

import pdb
import math
import numpy

def ind2config(setup, groups, NRPC, ind):
    
    # Note: this function assumes zero-indexing (e.g, for 40 runs, they should be listed as 0-39 in the index file created in gridRunPython.m)

    ## Get the parameters that have multiple values
    mvparams = [x for x in setup.keys() if type(setup[x]) == list]

    setup_working = {k:v for k,v in setup.items()}

    for param in list(setup_working):
        if param not in mvparams:
            setup_working.pop(param)
    ##    

    tvd = {} # temporary value dictionary
    
    ## Replace group fields with temporary fields
    for gn, group in enumerate(groups):
        tempVar = 'temporaryVariable%d' % gn
        tvd[tempVar] = group

        if type(setup[group[0]]) == list:

            for gm in group: #gm: group member
                setup_working.pop(gm)
            setup_working[tempVar] = [x for x in range(len(setup[group[0]]))]
    ##

    # Get lengths of each list in setup_working
    lengths = [len(v) for v in setup_working.values()]

    # Append NRPC to the front
    lengths = [NRPC] + lengths

    # Get list of subscripted indices corresponding to ind
    subidx = {k:v for k,v in zip(setup_working.keys(), lengths[1:])}
    for nl, k in enumerate(subidx):
        subidx[k] = math.floor(ind / numpy.prod(lengths[0 : nl + 1])) % lengths[nl + 1]

    # Replace fields in setup with specific config
    config = {k:v for k,v in setup.items()}

    for k in setup_working.keys():

        if k in list(config): # not member of a group            
            config[k] = setup[k][subidx[k]]
        elif k in list(tvd): # member of a group
            group = tvd[k]
            for gm in group: #gm: group member
                config[gm] = setup[gm][subidx[k]]

    # Add config_num_in_group and config_group_num
    config['config_num_in_group'] = (ind + 1) % NRPC
    if config['config_num_in_group'] == 0:
        config['config_num_in_group'] = NRPC

    config['config_group_num'] = math.floor(ind / NRPC) + 1
    
    return config

    

def default(): # Output default configuration
    config = {} # Establish config dictionary

    # Default values for properties of the region

    # The number of worlds with identical starting conditions and variables to stochastically simulate
    config['num_worlds'] = 5
    # The number of cases at the start of the simulation
    config['starting_cases'] = 20
    
    # Stopping conditions:
    # Number of days that the simulation lasts
    config['end_day'] = 80
    # Maximum number of current cases before program stops
    config['max_num_current_cases'] = 15000
    
    # The mean time between an individual being exposed and them becoming infectious
    config['mean_latent_period'] = 2
    # The standard deviation of latent period
    config['sd_latent_period'] = 1
    # The mean time between an individual being exposed and them becoming clinical
    config['mean_incubation_period'] = 5
    # The standard deviation of incubation period
    config['sd_incubation_period'] = 1
    
    # The probability that a person who has been called by public health will get tested on any given day
    config['p_test_given_call'] = 0.5
    # The probability that a person who has no symptomes and has not been notified in any way will get a test
    config['p_test_baseline'] = 0.1
    # The probability that a person who has received a notification through the app will get tested on any given day
    config['p_test_given_notification'] = 0.3
    # The probability that a person who is symptomatic will get tested on any given day
    config['p_test_given_symptomatic'] = 0.5
    # The probability that a person who have been exposed will test positive
    config['p_positive_test_given_exposed'] = 0.5
    # The probability that someone who is presymptomatic will test positive
    config['p_positive_test_given_presymptomatic'] = 0.75
    # The probability that someone who is symptomatic will test positive
    config['p_positive_test_given_symptomatic'] = 0.9
    # The probability that someone who is asymptomatic will test positive
    config['p_positive_test_given_asymptomatic'] = 0.9
    # The probability that a person is running the app
    config['p_running_app'] = 0.1
    # The probability that a close contact running the app will successfully handshake with their generator (given the generator is also running the app)
    config['p_app_detects_generator'] = 0.9
    # The probability that a call from public health will reach the person
    config['p_successful_call'] = 0.5
    # The probability that a person will call public health after a positive test
    config['p_contact_public_health_after_positive_test'] = 0.5
    # The probability that a person will call public health after receiving an AEN notificaiton
    config['p_contact_public_health_after_AEN_notification'] = 0.5
    # The probability that a person who is running the app who gets a positive test will upload their key to public health
    config['p_upload_key_given_positive_test'] = 0.75
    # The probability that an individual will be found using manual contact tracing
    config['p_identify_individual_using_manual_contact_tracing'] = 0.1
    # The likelyhood an infected person will be asymptomatic
    config['p_asymptomatic_rate'] = 0.5
    
    # The average number of contacts that an individual encounters each day....
    # ...if they take no precautions - Poisson distribution
    config['mean_new_cases'] = 0.4
    # ...if they social distancing / being cautious
    config['mean_new_cases_minimal'] = 0.3
    # ...after entering self-Quarantine 
    config['mean_new_cases_moderate'] = 0.2
    # ...after after entering self-isolation - Poisson distribution
    config['mean_new_cases_maximal'] = 0.1
    
    # The proportion of contacts that were flagged as being a potential case, but is uninfected
    config['false_positive_rate'] = 0.5
    # The False Discovery Rate (FDR), used to create additional false positives picked up automatically by the system. 0.5 will equal new cases.
    config['false_discovery_rate'] = 0.25
    
    # Probabilities associated with entering various levels of restricted movement given the person is symptomatic
    config['p_maximal_restriction_given_symptomatic'] = 0.5
    config['p_moderate_restriction_given_symptomatic'] = 0.75
    config['p_minimal_restriction_given_symptomatic'] = 0.9
    # Probabilities associated with entering various levels of restricted movement given the person receives a positive test
    config['p_maximal_restriction_given_positive_test'] = 0.75
    config['p_moderate_restriction_given_positive_test'] = 0.85
    config['p_minimal_restriction_given_positive_test'] = 0.95
    # Probabilities associated with entering various levels of restricted movement given the person is successfully called by PH
    config['p_maximal_restriction_given_PH_call'] = 0.5
    config['p_moderate_restriction_given_PH_call'] = 0.75
    config['p_minimal_restriction_given_PH_call'] = 0.9
    # Probabilities associated with entering various levels of restricted movement given the person is notified by AEN
    config['p_maximal_restriction_given_AEN_notification'] = 0.5
    config['p_moderate_restriction_given_AEN_notification'] = 0.75
    config['p_minimal_restriction_given_AEN_notification'] = 0.9
    
    # The mean and standard deviation of number of days that it takes for a test to get back (normal distribution)
    config['test_delay'], config['test_delay_sigma'] = (3,1)
    
    # Number of days it takes to be sure of recovery from infection
    config['recovery_length'] = 14
    # The number of contact tracers
    config['n_contact_tracers'] = 40
    # The number of hours each contact tracer can spend on calling in a day
    config['work_day_length'] = 4
    # The length of time that a missed call takes (in hours)
    config['missed_call_time'] = 0.05
    # The length of time that a contact tracer takes to perform contact tracing on an index case (in hours)
    config['index_trace_call_time'] = 1
    # The length of time that a missed call takes (in hours)
    config['alert_call_time'] = 0.1

    return config
