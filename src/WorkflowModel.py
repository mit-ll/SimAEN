# -*- coding: utf-8 -*-
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

# Copyright (c) 2020 Massachusetts Institute of Technology
# SPDX short identifier: MIT

#Developed as part of: SimAEN, 2020
#Authors: DI25756, JO26228, ED22162
"""
Created on Thu Jul 30 15:41:14 2020

@author: DI25756, JO26228, ED22162
"""

from random import random, randint, normalvariate, gauss
import numpy as np
import sys
import matplotlib.pyplot as plt #for plotting
import pdb #for debugging
from math import floor
import os # to identify if JSON file exists
import sys # to accept input arguments for, among other potential things, grid functionality
import json # to read JSON file
import pprint # to show configuration being used in terminal output
import math
import time # to time simulation

if __name__ == "__main__":
    from readConfig import readConfig
    from pytools import process_logs
    from pytools.config import ind2config
    import pytools.config # to work with simulation configuration
    # import pytools.process_logs # to process event logs
else:
    from src.readConfig import readConfig
    from src.pytools import process_logs
    from src.pytools.config import ind2config
    import src.pytools.config # to work with simulation configuration
    # import src.pytools.process_logs # to process event logs

# Make simulation configuration ("config") a global variable
# global config

# Add global variable tracking number of Individuals
global individual_id

class World:
    total_cases = 0                # This keeps track of the number of cases that have ever been generated
    num_called = 0                 # The number of people that have been called by public health
    
    verbose = False
    
    def __init__(self, config, number_to_generate=1, name=None):
        global worldCount
        
        self.index = worldCount         # The id of this world
        worldCount += 1                 # Increment the number of worlds
        if name is None:
            self.name = 'World ' + repr(self.index)        # Default world name
        else:
            self.name = name            # The name of this world
        for k in config:
            #print('Setting '+k+' to '+repr(config[k]))
            setattr(self,k,config[k]) # set world attributes based on config dictionary

        # Ensure that probabilities of starting behavior in minimal, moderate, or maximal states do not exceed 100%
        if self.p_start_min + self.p_start_mod + self.p_start_max > 1:
            raise Exception('Sum of starting behavior probabilities exceed 1')

        # Generate log for this world
        self.log = Log(self)

        # All of the currently active individuals
        self.cases = []
        # List of cases that have been tested positive and submited their key via the app
        self.index_cases = []
        # List of people waiting for a test
        self.test_queue = []
        # The list of individuals that have had a contact event, are running the app, are known about, and need to be called by public health    
        self.call_list = []
        # The total amount of man-hours that are worked by contact tracers each day
        self.total_available_calling_time = self.n_contact_tracers * self.work_day_length
        # Tracker for the number of calls by public health that reach an individual
        self.number_successfully_called_on_day = 0
        # Tracker for the number of calls by public health does not reach an individual
        self.number_missed_calls_on_day = 0
        # Tracker for the number of new cases on the day
        self.number_new_cases_on_day = 0
        # Tracker for the total number of calls made        
        self.number_called_all_time = 0
        # Tracker for how much time ph spent in calls today, in manhours
        self.call_time_today = 0
        # Tracker for how much time ph spent in calls overall, in manhours
        self.call_time_total = 0
        # Tracker for the number of new false positive cases being tracked today
        self.number_false_positives_today = 0
        # Tracker for the number of false positive cases ever created
        self.number_false_positives_total = 0
        # Tracker for the number of new falsely discovered cases being picked up by the app
        self.number_false_discovered_today = 0
        # Tracker for the number of falsely discovered cases ever created
        self.number_false_discovered_total = 0
        # Tracker for the number of people notified
        self.number_notified = 0
        # Tracker for the number of people notified but are uninfected
        self.number_uninfected_notified = 0
        # Tracker for the number of people who have entered moderate restriction
        self.number_moderate_restriction = 0
        # Tracker for the number of people who have entered moderate restriction but are uninfected
        self.number_uninfected_moderate_restriction = 0
        # Tracker for the number of people who have entered maximal restriction
        self.number_maximal_restriction = 0
        # Tracker for the number of people who have entered maximal restriction but are uninfected
        self.number_uninfected_maximal_restriction = 0
        
        # Tracker that is returned to the matlab frontend
        self.matlab = {
            'day': [],
            'current_cases': [],
        	'total_cases': [],
        	'called_today': [],
            'missed_today': [],
        	'left_on_call_list': [],
        	'total_called': [],
            'call_time_today': [],
            'call_time_total': [],
            'new_cases': [],
            'false_positives_today': [],
            'false_positives_total': [],
            'false_discovered_today': [],
            'false_discovered_total': [],
            'number_notified': [],
            'number_uninfected_notified': [],
            'number_moderate_restriction': [],
            'number_uninfected_moderate_restriction': [],
            'number_maximal_restriction': [],
            'number_uninfected_maximal_restriction': []
        }
        
        # Generate all of the initial cases
        for i in range(number_to_generate):
            self.cases.append(Individual(myWorld=self, daysInSystem=randint(0, self.recovery_length - 1), behavior='Normal'))

            # Update log - generation
            self.log.append(self.cases[-1], eventType = 'generation')
            
    def num_active_cases(self):
        num_active = {'Uninfected':0,
                      'Exposed':0,
                      'Presymptomatic':0,
                      'Symptomatic':0,
                      'Asymptomatic':0,
                      'Recovered':0}
        for case in self.cases:
            num_active[case.infectionStatus] += 1
        return(num_active)

    def advanceDay(self):
        global day
        # Update records for plotting (P)
        self.matlab['day'].append(day)
        current_cases = self.num_active_cases()
        self.matlab['current_cases'].append(current_cases['Exposed']+current_cases['Presymptomatic']+current_cases['Symptomatic']+current_cases['Asymptomatic'])
        self.matlab['total_cases'].append(self.total_cases)
        self.matlab['called_today'].append(self.number_successfully_called_on_day)
        self.matlab['missed_today'].append(self.number_missed_calls_on_day)
        self.matlab['left_on_call_list'].append(len(self.call_list))
        self.matlab['total_called'].append(self.number_called_all_time)
        self.matlab['call_time_today'].append(self.call_time_today)
        self.matlab['call_time_total'].append(self.call_time_total)
        self.matlab['new_cases'].append(self.number_new_cases_on_day)
        self.matlab['false_positives_today'].append(self.number_false_positives_today)
        self.matlab['false_positives_total'].append(self.number_false_positives_total)
        self.matlab['false_discovered_today'].append(self.number_false_discovered_today)
        self.matlab['false_discovered_total'].append(self.number_false_discovered_total)
        self.matlab['number_notified'].append(self.number_notified)
        self.matlab['number_uninfected_notified'].append(self.number_uninfected_notified)
        self.matlab['number_moderate_restriction'].append(self.number_moderate_restriction)
        self.matlab['number_uninfected_moderate_restriction'].append(self.number_uninfected_moderate_restriction)
        self.matlab['number_maximal_restriction'].append(self.number_maximal_restriction)
        self.matlab['number_uninfected_maximal_restriction'].append(self.number_uninfected_maximal_restriction)
        
        # Reset all of the trackers
        self.number_successfully_called_on_day = 0
        self.number_new_cases_on_day = 0
        self.number_missed_calls_on_day = 0

        # Advance day for each each Individual in this world object
        for case in self.cases:
            case.advanceDay()
        for case in self.call_list:
            case.daysOnCallList += 1
    
    def performManualTrace(self, index):
        index.hasBeenManualContactTraced = True
        
        # descendants = [x for x in self.cases if x.generator is index]
        # for case in self.cases:
        # for case in descendants:   
        num_contacts_recalled =  0   
        num_contacts_forgotten = 0

        for case in index.descendants:

            if case.mctTraceableByGenerator and not case.falseDiscovery:                

                if num_contacts_recalled < case.myWorld.max_contacts_recalled:
                    
                    num_contacts_recalled += 1

                    case.addToCallList()
                    case.identifiedThroughMCT = True
                    # Update log - identified contact
                    case.generator.myWorld.log.append(case.generator, eventType = 'identifiedContact', contact = case.myID)

                    # Update log - addition to public health call list
                    case.myWorld.log.append(case, eventType = 'addedToCallList', basis = 'manual_contact_tracing', origin = index.myID)                    

                else:                    
                    num_contacts_forgotten += 1

        if num_contacts_forgotten > 0:
            index.myWorld.log.append(index, eventType = 'memoryLimitReached', numContactsForgotten = num_contacts_forgotten)
                    

        # if random() < self.p_identify_individual_using_manual_contact_tracing: # Sometimes we will find the generator of the index case
        if index.generator and index.mctTraceableByGenerator: # Assmes that if index's generator recognizes index, then index recognizes index's generator
            index.generator.addToCallList()

            # Update log - identified contact
            index.myWorld.log.append(index, eventType = 'identifiedContact', contact = index.generator.myID)

            # Update log - addition to public health call list
            index.generator.myWorld.log.append(index.generator, eventType = 'addedToCallList', basis = 'manual_contact_tracing', origin = index.myID)
        
    def processCallList(self):
        missed_connections = []
        self.call_time_today = 0
        if self.verbose:
            print('Start ', end='')
            print([x.id for x in self.call_list])
            
        # Call people until everyone is called or all of the time is used up
        while len(self.call_list) > 0 and self.call_time_today < self.total_available_calling_time:
            case = self.call_list.pop(0) # Grab the first individual in the call list
                
            if (case.callAttempts < (self.max_call_attempts * case.timesOnCallList)) and case.daysOnCallList < self.recovery_length:
                if case.call(): # This returns True if the call is successful
                    if case in self.index_cases and not case.hasBeenManualContactTraced:
                        # Update log - public health call
                        case.myWorld.log.append(case, eventType = 'publicHealthCall', success = True, callType = 'index_case', callNumber = case.callAttempts)
                        
                        self.call_time_today += self.index_trace_call_time
                        self.performManualTrace(case)
                        
                    else:

                        # Update log - public health call
                        case.myWorld.log.append(case, eventType = 'publicHealthCall', success = True, callType = 'contact_case', callNumber = case.callAttempts)

                        self.call_time_today += self.alert_call_time
                    self.number_successfully_called_on_day += 1
                    if self.verbose:
                        print('* called: '+repr(case.index))
                else:

                    # Update log - public health call
                    if case in self.index_cases:
                        case.myWorld.log.append(case, eventType = 'publicHealthCall', success = False, callType = 'index_case', callNumber = case.callAttempts)
                    else:
                        case.myWorld.log.append(case, eventType = 'publicHealthCall', success = False, callType = 'contact_case', callNumber = case.callAttempts)

                    self.call_time_today += self.missed_call_time
                    missed_connections.append(case) # Add them to the list of people who were not successfully called
                    self.number_missed_calls_on_day += 1
                    if self.verbose:
                        print('* Missed: '+repr(case.index))
            else:
                exceededMaxAttemps = case.callAttempts >= (self.max_call_attempts * case.timesOnCallList)
                exceededMaxDays = case.daysOnCallList >= self.recovery_length
                case.myWorld.log.append(case, eventType = 'droppedFromCallList', exceededMaxAttemps = exceededMaxAttemps, exceededMaxDays = exceededMaxDays, numAttemps = case.callAttempts, numDays = case.daysOnCallList)
        
        if self.verbose:
            print('End ',end='')
            print([x.id for x in self.call_list])
            print([x.id for x in missed_connections])
        self.call_list.extend(missed_connections)
        
        self.number_called_all_time += self.number_successfully_called_on_day
        self.call_time_today = round(self.call_time_today, 2)
        self.call_time_total += self.call_time_today
        self.call_time_total = round(self.call_time_total, 2)

    def transmit(self):
        new_cases = []
        self.number_false_positives_today = 0
        self.number_false_discovered_today = 0

        # For every current case, call transmission and add returned new cases to a list
        for case in self.cases:
            if case.infectionStatus != 'Recovered':
                new_cases.extend(case.transmit())
        self.cases.extend(new_cases)

        self.number_new_cases_on_day += len(new_cases)
        self.number_false_positives_total += self.number_false_positives_today
        self.number_false_discovered_total += self.number_false_discovered_today
        
    def test(self):
        for case in self.cases:
            if case.infectionStatus != 'Recovered':
                # oldTested = case.tested
                case.getsTested()
    
                # if oldTested != case.tested:
                #     if case.testResult == 'Positive':
                #         testResultPositive = True
                #     elif case.testResult == 'Negative':
                #         testResultPositive = False
                #     elif case.testResult == None:
                #         testResultPositive = None
                #     else:
                #         raise Exception("Unrecognized testResult %s" % case.testResult)
                #     case.myWorld.log.append(case, eventType = 'testChange', testResultPositive = testResultPositive)

            
    def automaticTrace(self):
        # TODO: some people are running the app, but it does not detect the person who infects them
        # TODO: add to call list with a flag that they are not going to be contact traced
        for case in self.cases: # For every person
            if case.generator: # Avoid crashes due to dereferencing a null pointer
                # If a person is running the app AND
                #   their generator has uploaded their key AND
                #   their app recognized the generator AND 
                #   they have not uploaded a key AND
                #   they have not been notified already
                # then the person will receive a notification
                if case.hasApp and \
                        case.generator.keyUploaded and \
                        case.appDetectsGenerator and \
                        (not case.keyUploaded):
                    case.dayContactRegistered = case.daysInSystem
                    case.notified += 1         # Immediately send this person an automatic notification

                    # Log the AEN
                    case.myWorld.log.append(case, eventType = 'aen', origin = case.generator.myID)

                    self.number_notified += 1
                    if case.infectionStatus == 'Uninfected':
                        self.number_uninfected_notified += 1

                    if random() < self.p_contact_public_health_after_AEN_notification: # This is a proxy for this person calling public health themselves after getting notified, which would be independent of the typical call list
                        case.addToCallList()

                        # Update log - addition to public health call list
                        case.myWorld.log.append(case, eventType = 'addedToCallList', basis = 'aen_response', origin = None)
                
                # We also add generators (if they meet the criteria) if one of the Individuals they generated uploaded their key
                # If a person's generator is running the app AND
                #   has uploaded their key AND
                #   their generator is running the app AND
                #   their app detected their generator's app
                #   their generator has not uploaded a key AND
                # then the person will receive a notification
                if case.hasApp and \
                        case.keyUploaded and \
                        case.generator.hasApp and \
                        case.appDetectedByGenerator and \
                        (not case.generator.keyUploaded):
                    case.generator.dayContactRegistered = case.generator.daysInSystem
                    case.generator.notified += 1         # Immediately send this person an automatic notification

                    # Log the AEN
                    case.generator.myWorld.log.append(case.generator, eventType = 'aen', origin = case.myID)

                    # TODO - do we need this block of code here?  Looks like a copy and paste from previous if statement
                    self.number_notified += 1
                    if case.generator.infectionStatus == 'Uninfected':
                        self.number_uninfected_notified += 1

                    if random() < self.p_contact_public_health_after_AEN_notification: # This is a proxy for this generator calling public health themselves after getting notified, which would be independent of the typical call list
                        case.generator.addToCallList()

                        # Update log - addition to public health call list
                        case.myWorld.log.append(case, eventType = 'addedToCallList', basis = 'aen_response', origin = None)

    def cleanup(self):

        maintainedCases = [] # We have to remove people that have been in the system too long
        while self.cases:
            case = self.cases.pop()
            # if case.interactionPossible():
            if case.daysInSystem <= self.recovery_length:
                maintainedCases.append(case)
            elif (case.daysInSystem - case.dayTested) <= self.recovery_length:     # NOTE: We may want to control the time to stay on the index list more precisely
                maintainedCases.append(case)
            elif ((case.daysInSystem - case.dayContactRegistered) <= self.recovery_length):
                maintainedCases.append(case)
            else:
                # log the removal of the case
                case.myWorld.log.append(case, eventType = 'removal', interactionPossible = True)

                # remove from generator's descendant list
                if case.generator:
                    case.generator.descendants.remove(case)
            # else:
            #     # log the removal of the case
            #     case.myWorld.log.append(case, eventType = 'removal', interactionPossible = False)

            #     # remove from generator's descendant list
            #     if case.generator:
            #         case.generator.descendants.remove(case)

        self.cases = maintainedCases
        
        maintainedCases = [] # The Index case list needs to be maintained as well
        while self.index_cases:
            case = self.index_cases.pop()
            if case.daysInSystem <= self.recovery_length:
                maintainedCases.append(case)
            elif (case.daysInSystem - case.dayTested) <= self.recovery_length:
                maintainedCases.append(case)
            elif ((case.daysInSystem - case.dayContactRegistered) <= self.recovery_length):
                maintainedCases.append(case)
        self.index_cases = maintainedCases
        
        if not len(self.cases):
            return False
        else:
            return True
        
class Individual:
    def __init__(self, myWorld, generator=None, daysInSystem=0, hasApp=None, mctTraceableByGenerator=None, appDetectsGenerator=False, appDetectedByGenerator=False, infectionStatus='Exposed', behavior='Proportional', wearingMask=None):

        self.myWorld = myWorld                  # The world this person belongs to
        self.generator = generator              # The id of the person that came into close contact with this person        
        self.descendants = []                   # The id(s) of this Individual's descendant(s)
        self.daysInSystem = daysInSystem        # The number of days that the person has been in the system
        self.myWorld.total_cases += 1           # Increment the number of people
        self.myID = self.myWorld.total_cases    # A unique (within each world) identifier for each Individual
        self.test_countdown = float('inf')      # A countdown to receiving test results
        self.dayTested = 0                      # The day the person was tested
        self.dayContactRegistered = 0

        # Individual state trackers
        if hasApp is None and random() < self.myWorld.p_running_app:
            self.hasApp = True          # True if this person is running the app
        elif hasApp is None:
            self.hasApp = False
        else:
            self.hasApp = hasApp

        if mctTraceableByGenerator is None and random() < self.myWorld.p_identify_individual_using_manual_contact_tracing:
            self.mctTraceableByGenerator = True
        elif mctTraceableByGenerator is None:
            self.mctTraceableByGenerator = False
        else:
            self.mctTraceableByGenerator = mctTraceableByGenerator


        self.appDetectsGenerator = appDetectsGenerator
        self.appDetectedByGenerator = appDetectedByGenerator

        self.falseDiscovery = False
        self.notified = 0                       # The person has been notified automatically by the app
        self.called = False                     # The person has been called by public health
        self.hasBeenManualContactTraced = False # True once the person has been contact traced
        self.tested = False                     # The person has gone and been tested
        self.testResultReceived = False         # True if the person has received test results
        self.keyUploaded = False                # True if the person has uploaded a received key to the sytem. Just a shorthand to not have to interogate the index list as often.
        self.testResult = None                  # The person's actual test results. Possible options: Positive, Negative
        self.contacts_public_health = False     # Whether the person will contact public health when given a positive test
        self.infectionStatus = infectionStatus  # Infection Status affects ability to transmit, and likelyhood of getting tested. Possible options: Exposed, Presymptomatic, Asymptomatic, Symptomatic, Uninfected, Recovered
        self.testdayInfectionStatus = None      # The infection status on the day this person gets tested
        self.test_number = 0
        self.test_cooldown = 0
        self.identifiedThroughMCT = False
        if behavior == 'Proportional':
            self.behavior = 'Normal'
            self.checkForChangeInMovementRestrictions(self.myWorld.p_start_max, self.myWorld.p_start_mod, self.myWorld.p_start_min, initialization = True)
        else:
            self.behavior = behavior                # Behavior affects amount of transmission. Possible options: minimal_restriction, moderate_restriction, maximal_restriction
        self.initialBehavior = self.behavior

        if wearingMask == None:
            self.wearingMask = self.checkForMask()
        else:
            self.wearingMask = wearingMask
        
        self.callAttempts = 0                   # The number of times a public health official has tried to contact this person
        self.daysOnCallList = 0                 # The number of days that the person has been on the call list
        self.timesOnCallList = 0                # The number of times this person has been added to the call list
        # The amount of time between exposure and the person becoming infectious
        self.latentPeriod = int(max((1, self.myWorld.mean_latent_period + gauss(0, self.myWorld.sd_latent_period))))
        # The amount of time between exposure and the person becoming clinical
        self.incubationPeriod = int(max((self.latentPeriod + 1, self.myWorld.mean_incubation_period + gauss(0, self.myWorld.sd_incubation_period))))        
    
    def rollNewIndividual(self):
        # Note: 'self' is the generator of a potential new Individual

        # Get behavior
        newBehavior = Individual.rollMovementRestriction(self.myWorld.p_start_max, self.myWorld.p_start_mod, self.myWorld.p_start_min, initialization = True)

        # Get mask use
        newWearingMask = Individual.rollMaskUse(newBehavior, self.myWorld.p_mask_given_norm, self.myWorld.p_mask_given_max, self.myWorld.p_mask_given_mod, self.myWorld.p_mask_given_min)

        # Get infectionStatus of potential new Individual
        if self.infectionStatus in ['Exposed', 'Uninfected', 'Recovered']: # Generators in these states do not infect others
            newInfectionStatus = 'Uninfected'
        else: # Generators in the other states can infect others            
            newInfectionStatus = Individual.rollInfectionStatus(self.myWorld.p_transmission_given_no_masks, self.wearingMask, newWearingMask, self.myWorld.mask_effect)

        # Get app use
        newHasApp = random() < self.myWorld.p_running_app

        # Get app detects generator and app detected by generator
        if self.hasApp and newHasApp and random() < self.myWorld.p_app_detects_generator:
            newAppDetectsGenerator = True
            newAppDetectedByGenerator = True
        else:
            newAppDetectsGenerator = False
            newAppDetectedByGenerator = False

        # Get mctTraceableByGenerator
        newMctTraceableByGenerator = random() < self.myWorld.p_identify_individual_using_manual_contact_tracing

        # Get interaction possible
        newInteractionPossible = Individual.getInteractionPossible(newInfectionStatus, newMctTraceableByGenerator, newAppDetectsGenerator, newAppDetectedByGenerator)

        if newInteractionPossible:
            # Create new Individual
            newIndividual = Individual(myWorld=self.myWorld, \
                generator=self, \
                mctTraceableByGenerator=newMctTraceableByGenerator, \
                hasApp=newHasApp, \
                appDetectsGenerator=newAppDetectsGenerator, \
                appDetectedByGenerator=newAppDetectedByGenerator, \
                infectionStatus=newInfectionStatus, \
                behavior=newBehavior, \
                wearingMask=newWearingMask)
        else:
            # Do not create new individual
            newIndividual = None

        return newIndividual

    @staticmethod
    def rollMovementRestriction(p_max, p_mod, p_min, initialization = False):
        
        if initialization: # For when agent is created
            output = 'Normal'

            r = random()

            if r <= p_max:
                output = 'maximal_restriction'
            elif r <= p_mod + p_max:
                output = 'moderate_restriction'
            elif r <= p_min + p_mod + p_max:
                output = 'minimal_restriction'
        
        else: # For when existing agent's behavior is changing
            output = 'Normal'
            if random() < p_max:
                output = 'maximal_restriction'
            if random() < p_mod:
                output = 'moderate_restriction'
            if random() < p_min:
                output = 'minimal_restriction'
            
        return output


    @staticmethod
    def rollMaskUse(behavior, p_mask_norm, p_mask_max, p_mask_mod, p_mask_min):
        if behavior == 'Normal':
            return random() < p_mask_norm
        elif behavior == 'maximal_restriction':
            return random() < p_mask_max
        elif behavior == 'moderate_restriction':
            return random() < p_mask_mod
        elif behavior == 'minimal_restriction':
            return random() < p_mask_min
        else:
            raise Exception('Invalid behavior %s' % behavior)

    @staticmethod
    def getInteractionPossible(infectionStatus, mctTBG, appDetectsGenerator, appDetectedByGenerator):
        # This should only be used when individuals are created.
        if infectionStatus not in ['Uninfected', 'Recovered']: # (1)
            return True
        elif mctTBG: # (2)
            return True
        elif appDetectsGenerator or appDetectedByGenerator: # (3)
            return True
        else:
            return False        

    @staticmethod
    def rollInfectionStatus(p_transmission_no_masks, maskIndex, maskContact, maskEffect):
        p_transmission = p_transmission_no_masks
        if maskIndex:
            p_transmission = p_transmission * (1 - maskEffect)
        if maskContact:
            p_transmission = p_transmission * (1 - maskEffect)

        status = 'Exposed' if random() < p_transmission else 'Uninfected'
        return status

    def interactionPossible(self):
    # An agent can only 'interact' with others upon creation if it is (1) infected OR (2) recognizable through MCT OR (3) recognizable through AEN

        return Individual.getInteractionPossible(self.infectionStatus, self.mctTraceableByGenerator, self.appDetectsGenerator, self.appDetectedByGenerator)        

    def checkForMask(self):

        return Individual.rollMaskUse(self.behavior, self.myWorld.p_mask_given_norm, self.myWorld.p_mask_given_max, self.myWorld.p_mask_given_mod, self.myWorld.p_mask_given_min)

        # if self.behavior == 'Normal':
        #     return random() < self.myWorld.p_mask_given_norm
        # elif self.behavior == 'maximal_restriction':
        #     return random() < self.myWorld.p_mask_given_max
        # elif self.behavior == 'moderate_restriction':
        #     return random() < self.myWorld.p_mask_given_mod
        # elif self.behavior == 'minimal_restriction':
        #     return random() < self.myWorld.p_mask_given_min
        
    def maximalRestriction(self, initialization = False):
        if self.behavior != 'maximal_restriction':
            self.myWorld.number_maximal_restriction += 1

            if not initialization:
                wearingMaskBefore = self.wearingMask
                self.wearingMask = self.wearingMask or random() < self.myWorld.p_mask_given_max
                if self.wearingMask and not wearingMaskBefore:
                    self.myWorld.log.append(self, eventType = 'putOnMask')
            else:
                self.wearingMask = random() < self.myWorld.p_mask_given_max

            if self.infectionStatus == 'Uninfected':
                self.myWorld.number_uninfected_maximal_restriction += 1
        
        self.behavior = 'maximal_restriction'
    
    def moderateRestriction(self, initialization = False):
        if self.behavior != 'maximal_restriction':
            if self.behavior != 'moderate_restriction':

                if not initialization:
                    wearingMaskBefore = self.wearingMask
                    self.wearingMask = self.wearingMask or random() < self.myWorld.p_mask_given_mod
                    if self.wearingMask and not wearingMaskBefore:
                        self.myWorld.log.append(self, eventType = 'putOnMask')                
                else:
                    self.wearingMask = random() < self.myWorld.p_mask_given_mod

                    self.myWorld.number_moderate_restriction += 1
                    if self.infectionStatus == 'Uninfected':
                        self.myWorld.number_uninfected_moderate_restriction += 1
            self.behavior = 'moderate_restriction'
    
    def minimalRestriction(self, initialization = False):
        if self.behavior != 'maximal_restriction' and self.behavior != 'moderate_restriction' and self.behavior != 'minimal_restriction':
            
            if not initialization:
                wearingMaskBefore = self.wearingMask

                self.wearingMask = self.wearingMask or random() < self.myWorld.p_mask_given_min
                if self.wearingMask and not wearingMaskBefore:
                    self.myWorld.log.append(self, eventType = 'putOnMask')                
            else:
                self.wearingMask = random() < self.myWorld.p_mask_given_min

            self.behavior = 'minimal_restriction'
    
    def checkForChangeInMovementRestrictions(self, p_max, p_mod, p_min, initialization = False):
        
        potentialNewRestriction = Individual.rollMovementRestriction(p_max, p_mod, p_min, initialization = initialization)

        if potentialNewRestriction == 'Normal':
            pass
        elif potentialNewRestriction == 'maximal_restriction':
            self.maximalRestriction(initialization = initialization)
        elif potentialNewRestriction == 'moderate_restriction':
            self.moderateRestriction(initialization = initialization)
        elif potentialNewRestriction == 'minimal_restriction':
            self.minimalRestriction(initialization = initialization)
        else:
            raise Exception('Invalid potentialNewRestriction %s' % potentialNewRestriction)            
        
    def advanceDay(self): # This is a general container for things that happen when a day goes by
        
        # Mark down Individiual's state before day's changes to let us know if we need to generate events to log
        oldInfectionStatus = self.infectionStatus
        oldTestResultReceived = self.testResultReceived
        oldBehavior = self.behavior # behavior before any potential changes -- need this to know when to log behavior changes

        if self.infectionStatus == 'Exposed' and self.daysInSystem >= self.latentPeriod:
            self.infectionStatus = 'Presymptomatic'            
        if self.infectionStatus == 'Presymptomatic' and self.daysInSystem >= self.incubationPeriod:
            if random() < self.myWorld.p_asymptomatic_rate:
                self.infectionStatus = 'Asymptomatic'
            else:
                self.infectionStatus = 'Symptomatic'
        if self.daysInSystem >= self.myWorld.recovery_length and self.infectionStatus != 'Uninfected':
            self.infectionStatus = 'Recovered'
        # If infection status changed, log it
        if oldInfectionStatus != self.infectionStatus:            
            self.myWorld.log.append(self, eventType = 'infectionStatusChange')
        
        # Update this person's testing status
        self.test_countdown -= 1  # Indivduals that have been tested will have a non-infinite self.test_countdown so this will function as a countdown
        self.processTest()
        self.test_cooldown -= 1
        # If test result received status changed, log it
        # if oldTestResultReceived != self.testResultReceived:

            # if self.testResult == 'Positive':
            #     testResultPositive = True
            # elif self.testResult == 'Negative':
            #     testResultPositive = False
            # elif self.testResult == None:
            #     testResultPositive = None
            # else:
            #     raise Exception("Unrecognized testResult %s" % self.testResult)

            # self.myWorld.log.append(self, eventType = 'testChange', testResultPositive = testResultPositive)        

        # Update this person's behavior
        if self.infectionStatus != 'Recovered':
            self.updateBehavior()

        # If behavior changed, log it
        if oldBehavior != self.behavior:
            self.myWorld.log.append(self, eventType = 'behaviorChange')

        self.daysInSystem += 1 # Increment number of days this person has been in the system
        
    def processTest(self):
        if self.test_countdown <= 0:        # Test has been completed -- must be <=0 and not ==0 because some test_countdowns start at 0
            self.test_countdown = float('inf') # This will allow the individual to be tested again (if they are also Negative)
            self.testResultReceived = True  # Results came back!
            
            # Set test result based on various values of p(positive | infectious state)
            self.testResult = 'Negative'
            if self.testdayInfectionStatus == 'Exposed' and random() < self.myWorld.p_positive_test_given_exposed:
                self.testResult = 'Positive'
            elif self.testdayInfectionStatus == 'Presymptomatic' and random() < self.myWorld.p_positive_test_given_presymptomatic:
                self.testResult = 'Positive'
            elif self.testdayInfectionStatus == 'Symptomatic' and random() < self.myWorld.p_positive_test_given_symptomatic:
                self.testResult = 'Positive'
            elif self.testdayInfectionStatus == 'Asymptomatic' and random() < self.myWorld.p_positive_test_given_asymptomatic:
                self.testResult = 'Positive'

            if self.testResult == 'Negative': # If result is negative, set agent behavior back to initial behavior, if it's not symptomatic and passes probability check
                if self.infectionStatus != 'Symptomatic':
                    if random() < self.myWorld.p_starting_behavior_after_negative_test_no_symptoms:
                        self.behavior = self.initialBehavior                    

                    # self.checkForChangeInMovementRestrictions(self.myWorld.p_start_max, self.myWorld.p_start_mod, self.myWorld.p_start_min)
                testResultPositive = False
            elif self.testResult == 'Positive':
                testResultPositive = True

            # Log received test
            self.myWorld.log.append(self, eventType = 'receivedTestResult', testResultPositive = testResultPositive, testdayInfectionStatus = self.testdayInfectionStatus)                    

    def updateBehavior(self):
        # Every day we will check if a person alters their behavior based on their status (tested, called, etc.)
        if self.infectionStatus == 'Symptomatic':
            self.checkForChangeInMovementRestrictions(self.myWorld.p_maximal_restriction_given_symptomatic,\
                                                       self.myWorld.p_moderate_restriction_given_symptomatic,\
                                                       self.myWorld.p_minimal_restriction_given_symptomatic)
        if self.testResult == 'Positive':
            self.checkForChangeInMovementRestrictions(self.myWorld.p_maximal_restriction_given_positive_test,\
                                                       self.myWorld.p_moderate_restriction_given_positive_test,\
                                                       self.myWorld.p_minimal_restriction_given_positive_test)
            # People may become index cases if they have a positive test without the app. This will line the person up to get a manual trace.
            if random() < self.myWorld.p_contact_public_health_after_positive_test:
                if self not in self.myWorld.call_list and self.called == False and self.callAttempts == 0:
                    # Add the person to the call list
                    self.addToCallList()
                    # Update log - addition to public health call list
                    self.myWorld.log.append(self, eventType = 'addedToCallList', basis = 'positive_test_response', origin = None)

                    self.myWorld.index_cases.append(self)
            if not self.myWorld.key_upload_requires_call:
                if self.hasApp and (not self.keyUploaded) and (random() < self.myWorld.p_upload_key_given_positive_test):
                    self.myWorld.log.append(self, eventType = 'keyUpload')
                    self.keyUploaded = True
                    
            # People may become index cases if they have a positive test with the app. This will not add them to the call list.
            """
            if self.hasApp and (not self.keyUploaded) and (random() < self.myWorld.p_upload_key_given_positive_test):
                needsAdded = True
                self.myWorld.index_cases.append(self)
                self.needKeyUploaded = True
            """
                    
        if self.called:
            self.checkForChangeInMovementRestrictions(self.myWorld.p_maximal_restriction_given_PH_call,\
                                                       self.myWorld.p_moderate_restriction_given_PH_call,\
                                                       self.myWorld.p_minimal_restriction_given_PH_call)
        if self.notified:
            self.checkForChangeInMovementRestrictions(self.myWorld.p_maximal_restriction_given_AEN_notification,\
                                                       self.myWorld.p_moderate_restriction_given_AEN_notification,\
                                                       self.myWorld.p_minimal_restriction_given_AEN_notification)

    def addToCallList(self):
        self.myWorld.call_list.append(self)
        self.timesOnCallList += 1

    def call(self):
        #TODO: people should be more likely to pick up if they are expecting a call than if they aren't
        if self.identifiedThroughMCT == True:
            if random() < self.myWorld.p_successful_call_unanticipated:
                self.called = True
        else:
            if random() < self.myWorld.p_successful_call_anticipated:
                self.called = True
        if self.hasApp and \
                (random() < self.myWorld.p_upload_key_given_positive_test) and \
                self.called and \
                self.testResult == 'Positive' and\
                self.myWorld.key_upload_requires_call:
            self.keyUploaded = True
            self.myWorld.log.append(self, eventType = 'keyUpload')
        self.callAttempts += 1
        return self.called
        
    def transmit(self):
        # Establish new Individuals generated by this Individual
        
        # Initialize lists and counters to be outputted
        newContacts = [] 
        numNewCases = 0 
        newNewDetectedTrueCloseContacts = 0 

        if (self.infectionStatus != 'Recovered') and (self.infectionStatus != 'Uninfected'): # Can only create new Individuals if infectious
            
            ## Get number of new Individuals (i.e., number of true close contacts)
            if self.behavior == 'maximal_restriction':
                numNewCases = np.random.lognormal(mean=self.myWorld.mean_new_cases_maximal,sigma=self.myWorld.sigma_new_cases_maximal)
                #numNewCases = np.random.poisson(lam=self.myWorld.mean_new_cases_maximal)
            elif self.behavior == 'moderate_restriction':
                numNewCases = np.random.lognormal(mean=self.myWorld.mean_new_cases_moderate,sigma=self.myWorld.sigma_new_cases_moderate)
                #numNewCases = np.random.poisson(lam=self.myWorld.mean_new_cases_moderate)
            elif self.behavior == 'minimal_restriction':
                numNewCases = np.random.lognormal(mean=self.myWorld.mean_new_cases_minimal,sigma=self.myWorld.sigma_new_cases_minimal)
                #numNewCases = np.random.poisson(lam=self.myWorld.mean_new_cases_minimal)
            else:
                numNewCases = np.random.lognormal(mean=self.myWorld.mean_new_cases,sigma=self.myWorld.sigma_new_cases)
                #numNewCases = np.random.poisson(lam=self.myWorld.mean_new_cases)
            numNewCases = min((150,int(numNewCases)))
            ##
            
            # Keep track of the number of flashes
            num_flashes = 0

            # Roll the dice on a new Individual for each new case
            for i in range(numNewCases):
                new_individual = self.rollNewIndividual()

                if new_individual == None:
                    num_flashes += 1                    
                else:
                    if new_individual.appDetectsGenerator:
                        newNewDetectedTrueCloseContacts += 1

                    # Update log - generation of true contact
                    new_individual.myWorld.log.append(new_individual, eventType = 'generation')

                    # Append new individual to newContacts list
                    newContacts.append(new_individual)

                    if new_individual.infectionStatus == 'Uninfected' and new_individual.appDetectsGenerator:
                        self.myWorld.number_false_positives_today += 1


                # if self.infectionStatus == 'Exposed': # Generators who are in the Exposed state do not infect others
                #     newInfectionStatus = 'Uninfected'
                #     new_individual = Individual(myWorld=self.myWorld, generator=self, infectionStatus=newInfectionStatus)
                # else:                    
                #     # Instantiate the new Individual as 'pending' for infectionStatus.  Will change this shortly.
                #     new_individual = Individual(myWorld=self.myWorld, generator=self, infectionStatus='pending')

                #     # Get probability of transmission given mask wearing states of generator and generated individual
                #     p_transmission = self.myWorld.p_transmission_given_no_masks
                #     if self.wearingMask: # Generator is wearing mask
                #         p_transmission = p_transmission * (1 - self.myWorld.mask_effect)
                #     if new_individual.wearingMask: # New individual is wearing mask
                #         p_transmission = p_transmission * (1 - self.myWorld.mask_effect)
                    
                #     newInfectionStatus = 'Exposed' if random() < p_transmission else 'Uninfected'
                #     new_individual.infectionStatus = newInfectionStatus                      
                
                # if self.hasApp and new_individual.hasApp and random() < self.myWorld.p_app_detects_generator:
                #     new_individual.appDetectsGenerator = True
                #     new_individual.appDetectedByGenerator = True
                #     newNewDetectedTrueCloseContacts += 1

                # # Update log - generation of true contacts
                # new_individual.myWorld.log.append(new_individual, eventType = 'generation')
                
                # if not new_individual.interactionPossible(): # If this new contact cannot interact, then do not add it to newContacts list
                #     # Update log - removal of new contact
                #     new_individual.myWorld.log.append(new_individual, eventType = 'removal', interactionPossible = False)
                # else:
                #     newContacts.append(new_individual)

                # if newInfectionStatus == 'Uninfected' and new_individual.appDetectsGenerator:
                #     self.myWorld.number_false_positives_today += 1

            if num_flashes > 0:
                self.myWorld.log.append(self, eventType = 'flash', count = num_flashes) # Log the "flash in the pan" individuals (i.e., contacts that took place but without creating new agents)

            if self.hasApp:
                # numNewFalseDiscovered = (1 / self.myWorld.false_discovery_rate) - 1
                numNewFalseDiscovered = round((newNewDetectedTrueCloseContacts * self.myWorld.false_discovery_rate) / (1 - self.myWorld.false_discovery_rate))
                # for individual in range(newNewDetectedTrueCloseContacts):
                for individual in range(numNewFalseDiscovered):
                    # if random() < numNewFalseDiscovered:
                    new_individual = Individual(myWorld=self.myWorld, generator=self, infectionStatus='Uninfected', hasApp=True, mctTraceableByGenerator=False)
                    new_individual.appDetectsGenerator = True
                    new_individual.falseDiscovery = True
                    newContacts.append(new_individual)

                    # Update log - generation of false contacts
                    new_individual.myWorld.log.append(new_individual, eventType = 'generation')

                    # self.myWorld.number_false_positives_today += 1
                    self.myWorld.number_false_discovered_today += 1
        
        # Assign newContacts to Individual's descendant list
        self.descendants.extend(newContacts)

        return newContacts
    
    def getsTested(self): # We assume there is some baseline probability of getting tested
                          # and a different probability of getting tested if you have been called by public health

        if not self.testResult == 'Positive' and self.test_countdown == float('inf') and self.test_cooldown <= 0: # We can get tested as long as we have
                                                                                      #   not tested positive and we are not waiting 
            getsTest = random() < self.myWorld.p_test_baseline
            
            # Since people are more likely to heed multiple indicators (call + symptomatic, etc.) this is a series of ifs instead of an elif chain
            if self.notified:
                getsTest = getsTest or random() < self.myWorld.p_test_given_notification
            if self.infectionStatus == 'Symptomatic':
                getsTest = getsTest or random() < self.myWorld.p_test_given_symptomatic
            if self.called:
                getsTest = getsTest or random() < self.myWorld.p_test_given_call
            
            if getsTest: # TODO: consider making a queue
                self.test_number += 1
                self.test_cooldown = 2*self.test_number
                self.test_countdown = max(1,floor(self.myWorld.test_delay+gauss(0,self.myWorld.test_delay_sigma))) # ADDED: Test delay is not constant
                self.tested = True
                self.dayTested = self.daysInSystem
                self.testdayInfectionStatus = self.infectionStatus
    
                # Log the fact that individual took the test
                self.myWorld.log.append(self, eventType = 'tookTest', infectionStatus = self.infectionStatus, countdown = self.test_countdown)

class Log:
    def __init__(self, myWorld):
        self.myWorld = myWorld
        self.events = []
        self.eventNum = 0

    def logConfig(self):

        # Establish newEvent dictionary
        newEvent = {}

        # Increment counter
        self.eventNum += 1

    def append(self, individual, eventType = None, **kwargs):        
        
        # Establish newEvent dictionary
        newEvent = {}

        # Increment counter
        self.eventNum += 1

        # These variables are logged for every event type
        newEvent['eventNum'] = self.eventNum
        newEvent['day'] = day # this is a global variable
        newEvent['type'] = eventType
        if eventType != 'simulationEnd':
            newEvent['individual'] = individual.myID        
            newEvent['infectionStatus'] = individual.infectionStatus
        else:
            newEvent['individual'] = None
            newEvent['infectionStatus'] = None
        
        if eventType == 'generation': # Individual has been generated                        
            if individual.generator == None:
                newEvent['generator'] = None
                newEvent['appDetectsGenerator'] = None
                newEvent['falseDiscovery'] = None
                newEvent['generatorHasApp'] = None
                newEvent['generatorWearingMask'] = None
            else:
                newEvent['generator'] = individual.generator.myID
                newEvent['appDetectsGenerator'] = individual.appDetectsGenerator
                newEvent['falseDiscovery'] = individual.falseDiscovery
                newEvent['generatorHasApp'] = individual.generator.hasApp
                newEvent['generatorWearingMask'] = individual.generator.wearingMask

            newEvent['wearingMask'] = individual.wearingMask            
            newEvent['behavior'] = individual.behavior
            newEvent['hasApp'] = individual.hasApp
            newEvent['incubationPeriod'] = individual.incubationPeriod
            newEvent['latentPeriod'] = individual.latentPeriod
        elif eventType == 'behaviorChange':
            newEvent['behavior'] = individual.behavior
        elif eventType in ['aen', 'keyUpload', 'publicHealthCall', 'addedToCallList', 'identifiedContact', 'tookTest', 'receivedTestResult', 'putOnMask', 'infectionStatusChange', 'removal', 'droppedFromCallList', 'flash', 'simulationEnd', 'memoryLimitReached']:
            pass            
        else:
            raise Exception("Unrecognized eventType %s" % eventType)

        # Include all specified optional (kwargs) parameters in event
        newEvent = {**newEvent, **kwargs}

        # Append to list of events for this Log
        self.events.append(newEvent)


def main(makePlot = False, writeLog = {'events': True, 'arrays': True}, verbose = False, config = {}, configFile = '', eventFileIn = '', arrayFileIn = ''):

    print('=================================')
    print('======  Simulation Start  =======')
    print('=================================')

    # Get start time
    tic = time.time()

    # Handle simulation configuration
    defaultConfigFile = 'config.json'    

    if config != {}: # If a config dictionary has been specified as an argument to main(), use it and don't use a config file
        pass

    elif configFile == '' and os.path.exists(defaultConfigFile): # no config file specified; default file exists 

        print('**************************')
        print('Using default config file.')
        print('**************************')
        print('Config file: %s' % defaultConfigFile)

        with open(defaultConfigFile, 'r') as fp:            
            config = json.load(fp)

    elif configFile == '' and not os.path.exists(defaultConfigFile): # no config file specified, default file does not exist
        config = readConfig('pytools/config.txt') # use default in config.txt

        print('********************************')
        print('Using default config parameters.')
        print('********************************')

        pprint.pprint(config)
    elif configFile != '' and os.path.exists(configFile): # config file specified, exists

        print('***************************')
        print('Using specified config file.')
        print('***************************')
        print('Config file: %s' % configFile)

        with open(configFile, 'r') as fp:            
            config = json.load(fp)
    else: # config file specified, does not exist
        raise Exception('Specified config file %s not found.' % configFile)

    global day
    day = 0
    end_day = config['end_day']
    global_num_active_cases = 0
    global_num_total_cases = 0
    
    # Create worlds
    global worldCount
    worldCount = 0
    active_worlds = []
    for i in range(config['num_worlds']):
        pprint.pprint(config)
        active_worlds.append(World(config, number_to_generate=config['starting_cases']))
    
    # Make sure user sees terminal output
    sys.stdout.flush()

    # Run sim
    while True:
        global_num_active_cases = 0
        global_num_total_cases= 0
        for world in active_worlds:
            # Update each world
            world.advanceDay()
            world.transmit()
            world.test()
            world.automaticTrace()
            world.processCallList()
            keep_running = world.cleanup()

            # Contribute this world to the global trackers
            global_num_active_cases += len(world.cases)
            global_num_total_cases += world.total_cases
            # Print some results
            if verbose:
                print('World:                    '+repr(world.name))
                print('Day:                      '+repr(day)+'/'+repr(end_day))
                print('Cases:                    '+repr(len(world.cases)))
                print('Called today:             '+repr(world.number_successfully_called_on_day))
                print('Remaining on call list:   '+repr(len(world.call_list)))
                print('Missed calls today:       '+repr(world.number_missed_calls_on_day))
                print('Call time today:          '+repr(world.call_time_today) + ' hours')
                print('Call time total:          '+repr(world.call_time_total) + ' hours')
                print('Current index cases:      '+repr(len(world.index_cases)))
                print('New falsely discovered:   '+repr(world.number_false_discovered_today))
                print('New false positives:      '+repr(world.number_false_positives_today))
                print('Total regional cases:     '+repr(world.total_cases))
                print()
        if verbose:
            print('Global')
            print('Active global cases:   '+repr(global_num_active_cases))
            print('Total global cases:    '+repr(global_num_total_cases))
            print()
        else:
            print('Day: '+repr(day)+'/'+repr(end_day))
            print('Cases: '+repr(len(world.cases))+'/'+repr(config['max_num_current_cases']))
            print()

        # Break conditions for the while loop
        if day >= end_day:
            print('Maximum day (%d) reached.' % end_day)
            world.log.append(None, eventType = 'simulationEnd', condition = 'maxDayReached')
            break
        elif global_num_active_cases <= 0:
            print('No active cases.')
            world.log.append(None, eventType = 'simulationEnd', condition = 'noActiveCases')
            break
        elif global_num_active_cases > config['max_num_current_cases']:
            print('Maximum number of cases (%d) exceeded.' % config['max_num_current_cases'])
            world.log.append(None, eventType = 'simulationEnd', condition = 'maxCasesExceeded')
            break
        elif not keep_running:
            print('Everyone got better!')
            world.log.append(None, eventType = 'simulationEnd', condition = 'keepRunningFalse')
            break
        
        # Increment the day
        day += 1

        # Make sure user sees terminal output
        sys.stdout.flush()

    # Establish MATLAB output
    # matlab_output = []

    # Make some plots for each world if user desires    
    if makePlot:
        labels = ['Current Cases','Total Cases','called Today','Missed Calls Today','Left on Call List','Total called']    

    for world in active_worlds:

        # matlab_output.append(world.matlab)

        if makePlot:
            print('World: ' + repr(world.name))        
            for (c,value) in enumerate([*world.matlab.keys()]):
                if value != 'day':
                    plt.figure(c)
                    plt.plot(world.matlab['day'], world.matlab[value], label=labels[c])
                    plt.xlabel('Day')
                    plt.ylabel(labels[c])
                    plt.legend()
                    plt.show(block=False)

    # Output MATLAB results to JSON
    out = [sub.matlab for sub in active_worlds]
    with open('results.json', 'w') as fw:            
        json.dump(out, fw)

    # Output events and arrays to JSON   
    
    # processedEventsList = []
    # arraysList = []

    for n, world in enumerate(active_worlds):

        # Process logs
        raw_logs = {'config': config, 'events': world.log.events}
        (processedEvents, arrays) = process_logs.process_logs(raw_logs)

        if writeLog['events'] or writeLog['arrays']:

            # Get number of digits in max number of worlds
            ndig = math.ceil(math.log10(len(active_worlds) + 1))
        
            # File prefixes have not been specified
            if eventFileIn == '': # If no event prefix specified, use default
                eventFilePrefix = 'events_world.json'
            else:
                eventFilePrefix = eventFileIn                

            if arrayFileIn == '': # If no array prefix specified, use default
                arrayFilePrefix = 'arrays_world.json'
            else:
                arrayFilePrefix = arrayFileIn
            
            if len(active_worlds) > 1: # more than one world -- number output files
                # Event file
                directory = os.path.dirname(eventFilePrefix)
                (eventBaseName, extension) = os.path.splitext(os.path.basename(eventFilePrefix))
                num = '%0*d' % (ndig, n)
                eventFileOut = os.path.join(directory, eventBaseName + num + extension)

                directory = os.path.dirname(arrayFilePrefix)
                (arrayBaseName, extension) = os.path.splitext(os.path.basename(arrayFilePrefix))
                num = '%0*d' % (ndig, n)
                arrayFileOut = os.path.join(directory, arrayBaseName + num + extension)
            else: # only one world -- do not number output files
                eventFileOut = eventFilePrefix
                arrayFileOut = arrayFilePrefix
            
            # Output to JSON files
            if writeLog['events']:
                print('Writing event log file... ', end = '')
                sys.stdout.flush()
                with open(eventFileOut, 'w') as fw: # output event log                
                    outputEvents = {'config': config, 'events': processedEvents}                
                    json.dump(outputEvents, fw)
                    print('complete!')
            else:
                print('Bypassing event logging')
            
            if writeLog['arrays']:
                print('Writing array log file... ', end = '')
                sys.stdout.flush()
                with open(arrayFileOut, 'w') as fw: # output arrays                
                    outputArrays = {'config': config, 'arrays': arrays}
                    json.dump(outputArrays, fw)
                    print('complete!')
            else:
                print('Bypassing array logging')

    # Get end time
    toc = time.time() 
    print('=================================')
    print('=====  Simulation Complete  =====')
    print('=================================')
    print('Simulation duration: %0.1f seconds.' % (toc - tic))

    return active_worlds

##########################
#### CALL MAIN METHOD ####
##########################

# System arguments beyond the first one come from Grid runs.  Arguments:
#
# [0]: script name (not used)
# [1]: run index
# [2]: base results directory plus run index


if __name__ == "__main__":

    if len(sys.argv) == 1: # No files specified
        
        main()

    elif len(sys.argv) == 3: # (1) index and (2) base results directory plus run index

        # Get index
        ind = int(sys.argv[1])
        print('Index: %d' % ind)

        # Locate JSON file
        # file contains (a) setup, (b) NRPC, (c) groups, (d) writeLog, and (e) num_configs
        base_folder = os.path.dirname(sys.argv[2])
        print('Base folder: %s' % base_folder)
        setup_file = base_folder + '/config/setup.json'

        # Load JSON file
        with open(setup_file, 'r') as fp:
            setup_data = json.load(fp)

        ## Generate configuration
        setup = setup_data['setup']        
        NRPC = setup_data['NRPC']
        groups = setup_data['groups']
        writeLog = setup_data['writeLog']
        NC = setup_data['num_configs']

        config = ind2config(setup, groups, NRPC, ind)
        ##

        ## Generate eventFile and arrayFile
        ndig_configs = math.ceil(math.log10(NC + 1))
        ndig_nrpc = math.ceil(math.log10(NRPC + 1))

        eventFile = base_folder + '/logs/events/config%0*d_%0*d.json' % (ndig_configs, config['config_group_num'], ndig_nrpc, config['config_num_in_group'])
        arrayFile = base_folder + '/logs/arrays/config%0*d_%0*d.json' % (ndig_configs, config['config_group_num'], ndig_nrpc, config['config_num_in_group'])
        ##

        # Run the main routine
        main(writeLog = writeLog, config = config, eventFileIn = eventFile, arrayFileIn = arrayFile)

    # elif len(sys.argv) == 2: # Config file specified

        # configFile = sys.argv[1]
        # main(configFile = configFile)

    # elif len(sys.argv) == 3: # Config and log file specified

        # configFile = sys.argv[1]
        # baseLogFile = sys.argv[2]

        # eventFile = os.path.dirname(baseLogFile) + '/events/' + os.path.basename(baseLogFile)
        # arrayFile = os.path.dirname(baseLogFile) + '/arrays/' + os.path.basename(baseLogFile)

        # main(configFile = sys.argv[1], eventFileIn = eventFile, arrayFileIn = arrayFile)

    else:
        raise Exception("Invalid input arguments")
