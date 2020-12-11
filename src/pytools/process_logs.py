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
import json
import collections
import pdb
from itertools import compress
import numpy as np

def process_logs(raw_logs):
	
	# pdb.set_trace()

	event_types = \
		['generation',
		'infectionStatusChange', 
		'removal', 
		'tookTest', 
		'receivedTestResult', 
		'behaviorChange', 
		'aen', 
		'keyUpload', 
		'putOnMask', 
		'publicHealthCall', 
		'addedToCallList', 
		'droppedFromCallList',
		'identifiedContact',
		'flash',
		'simulationEnd',
		'memoryLimitReached']

	# print('Loading logs from file %s' % filein)
	# with open(filein, 'r') as fp:
	# 	raw_logs = json.load(fp)

	# Get simulation end log
	simEnd = [x for x in raw_logs['events'] if x['type'] == 'simulationEnd']
	if len(simEnd) > 1:
		raise Exception('Multiple simulationEnd events logged')
	elif len(simEnd) == 0:
		raise Exception('No simulationEnd events logged')

	# Get end_day
	end_day = raw_logs['config']['end_day']

	# Get last_day
	last_day = simEnd[0]['day']

	# Make sure that last_day is less than or equal to end_day
	if not last_day <= end_day:
		raise Exception("last_day must be less than or equal to end_day")
	
	# Get raw_events
	raw_events = raw_logs['events']

	# Update user
	print('=================================')
	print('====  Processing Event Logs  ====')
	print('=================================')

	# Organize events into 'events' dictionary by type
	print('Organizing events')
	events = {}
	for event_type in event_types:
		events[event_type] = [ev for ev in raw_events if ev['type'] == event_type]

	print('Get people')
	people = getPeople(events, last_day)

	print('Get days')
	days = getDays(events, last_day)

	print('Get ISM')
	ISM = getISM(events, last_day, end_day)
	ISM = np.ndarray.tolist(ISM)

	arrays = {'people': people, 'days': days, 'ISM': ISM}

	# Update user
	print('=================================')
	print('=====  Processing Complete  =====')
	print('=================================')

	return events, arrays

	# print('Outputting JSON file %s' % fileout)
	# with open(fileout, 'w') as fp:
	# 	json.dump(output, fp)

def getISM(events, last_day, end_day):

	# end_day: maximum possible last day of sim
	# last_day: actual last day of sim

	# Get list and number of individuals
	(individual, gen_is) = exf(events['generation'], ['individual', 'infectionStatus'])

	gen_is_num = i2num(gen_is)
	
	N = len(individual)

	# Create infection status matrix (ISM)
	#
	# One row for each individual in simulation; one column for each day of
	# simulation.  
	#
	# Column value guide -- on corresponding day, agent was in the following
	# state:
	#
	#     0: not present
	#
	#	 Normal Behavior
	#    ---------------
	#     1: exposed    
	#     2: pre-sym    
	#     3: sym        
	#     4: asym       
	#     5: uninfected 
	#     6: recovered  
	#
	#	 Minimal Restriction
	#    -------------------
	#    11: exposed   
	#    12: pre-sym    
	#    13: sym        
	#    14: asym       
	#    15: uninfected 
	#    16: recovered  
	#	
	#	 Moderate Restriction
	#    --------------------
	#    21: exposed    
	#    22: pre-sym    
	#    23: sym        
	#    24: asym       
	#    25: uninfected 
	#    26: recovered  
	#
	#	 Maximal Restriction
	#    -------------------
	#    31: exposed    
	#    32: pre-sym    
	#    33: sym        
	#    34: asym       
	#    35: uninfected 
	#    36: recovered  

	# Preallocate ISM
	ISM = np.zeros((N, end_day + 1), dtype = int)

	# Generation
	for n, ev in enumerate(events['generation']):
		if ev['behavior'] == 'Normal':
			addition = 0
		elif ev['behavior'] == 'minimal_restriction':
			addition = 10
		elif ev['behavior'] == 'moderate_restriction':
			addition = 20
		elif ev['behavior'] == 'maximal_restriction':
			addition = 30

		ISM[ev['individual'] - 1, ev['day'] : ] = addition + gen_is_num[n]

	# Infection status changes
	(isc_is,) = exf(events['infectionStatusChange'], ['infectionStatus'])

	isc_is_num = i2num(isc_is)

	for n, ev in enumerate(events['infectionStatusChange']):
		ISM[ev['individual'] - 1, ev['day'] : ] = isc_is_num[n]	

	# Behavior changes
	(bcdays,) = exf(events['behaviorChange'], ['day'])
	bcdays = np.array(bcdays)

	# Ensure that behavior changes are sorted by day
	I = np.argsort(bcdays)
	bcobj = np.array(events['behaviorChange'])
	bcobj = bcobj[I]

	# Populate ISM
	for ev in bcobj:
		row = ev['individual'] - 1

		if ev['behavior'] == 'Normal':
			ISM[row, ev['day'] :] = np.abs(ISM[row, ev['day'] :]) % 10
		elif ev['behavior'] == 'minimal_restriction':
			ISM[row, ev['day'] :] = 10 + np.abs(ISM[row, ev['day'] :]) % 10
		elif ev['behavior'] == 'moderate_restriction':
			ISM[row, ev['day'] :] = 20 + np.abs(ISM[row, ev['day'] :]) % 10
		elif ev['behavior'] == 'maximal_restriction':
			ISM[row, ev['day'] :] = 30 + np.abs(ISM[row, ev['day'] :]) % 10

	# Removal
	for n, ev in enumerate(events['removal']):
		ISM[ev['individual'] - 1, ev['day'] : ] = 0

	# Account for last_day and end_day being different (i.e., the sim ends before end_day due to max cases being reach or some other reason)
	if last_day < end_day:
		ISM[:, last_day + 1:] = 0

	return ISM

def i2num(infectionStatus):

	# Assertion
	if type(infectionStatus) != list:
		raise Exception('Input must be a list')

	# Preallocate
	out = np.zeros(np.shape(np.array(infectionStatus)), dtype = int)

	# List states
	states = ['Exposed', 'Presymptomatic', 'Symptomatic', 'Asymptomatic', 'Uninfected', 'Recovered'];

	# Iterate
	for n, el in enumerate(infectionStatus):
		if el == 'Exposed':
			out[n] = 1
		elif el == 'Presymptomatic':
			out[n] = 2
		elif el == 'Symptomatic':
			out[n] = 3
		elif el == 'Asymptomatic':
			out[n] = 4
		elif el == 'Uninfected':
			out[n] = 5
		elif el == 'Recovered':
			out[n] = 6
		else:
			raise Exception('Unrecognized input %s' % el)

	return out

def getDays(events, last_day):

	# Get list of days
	days = [i for i in range(0, last_day + 1)]

	## Preallocate	
	new_cases = [0] * len(days)
	new_infected_cases = [0] * len(days)

	flashes = [0] * len(days)

	recovered_cases = [0] * len(days)
	removed_cases = [0] * len(days)
	
	keyUploads = [0] * len(days)
	aen = [0] * len(days)
	aeni = [0] * len(days)
	tests = [0] * len(days)
	positive_test_results = [0] * len(days)
	negative_test_results = [0] * len(days)

	calls = [0] * len(days)
	successful_calls = [0] * len(days)
	additions_to_call_list = [0] * len(days)
	dropped_from_call_list = [0] * len(days)
	##

 #    called_today
 #    missed_today
 #    left_on_call_list
 #    total_called
 #    call_time_today
 #    call_time_total
 #    false_positives_today
 #    false_positives_total
 #    false_discovered_today
 #    false_discovered_total
 #    number_notified
 #    number_uninfected_notified
 #    number_moderate_restriction
 #    number_uninfected_moderate_restriction
 #    number_maximal_restriction
 #    number_uninfected_maximal_restriction

	# Get information from events
	print('     Extract information')
	(gen_day, gen_infStatus, gen_generator) = exf(events['generation'], ['day', 'infectionStatus', 'generator'])
	(key_day,) = exf(events['keyUpload'], ['day'])
	(aen_day, aen_is) = exf(events['aen'], ['day', 'infectionStatus'])
	(test_day,) = exf(events['tookTest'], ['day'])
	(isc_day, isc_is) = exf(events['infectionStatusChange'], ['day', 'infectionStatus'])
	(rem_day, rem_infStatus) = exf(events['removal'], ['day', 'infectionStatus'])
	(testResult_day, testResult_positive) = exf(events['receivedTestResult'], ['day', 'testResultPositive'])
	(call_day, call_success, call_type) = exf(events['publicHealthCall'], ['day', 'success', 'callType']) # callAttempts also available
	(added_day, added_basis) = exf(events['addedToCallList'], ['day', 'basis'])
	(dropped_day,) = exf(events['droppedFromCallList'], ['day'])
	(flash_day, flash_count) = exf(events['flash'], ['day', 'count'])

	# Make sure that all removal events have Uninfected or Recovered patients
	if not all([s in ['Uninfected', 'Recovered'] for s in rem_infStatus]):
		raise Exception('Some agents have been removed from simulation when not Uninfected or Recovered.')

	# Number of new cases each day
	gen_with_generators_day = compressMany(gen_day, [x != None for x in gen_generator])
	# C_nc = collections.Counter(gen_with_generators_day)
	C_nc = collections.Counter(gen_day)

	# Number of new infected cases each day	
	# igen_with_generators_day = compressMany(gen_day, [x != None for x in gen_generator], [x != 'Uninfected' for x in gen_infStatus])
	igen_day = compressMany(gen_day, [x != 'Uninfected' for x in gen_infStatus])
	# C_nic = collections.Counter(igen_with_generators_day)
	C_nic = collections.Counter(igen_day)

	# Number of removals each day
	C_rem = collections.Counter(rem_day)

	# Number of flashes each day
	C_flash = collections.Counter(flash_day) # At this point, C_flash captures the number of flash events, not the total number of flashes.  
											 # Flash events collapse several flashes into one event.
	for day in C_flash.keys():
		counts_on_day = compressMany(flash_count, [x == day for x in flash_day])
		C_flash[day] = sum(counts_on_day)

	# Number of recoveries each day
	isc_to_recovered_day = compressMany(isc_day, [x == 'Recovered' for x in isc_is])
	C_recovery = collections.Counter(isc_to_recovered_day)

	# Key uploads
	C_ku = collections.Counter(key_day)

	## AEN
	# All AEN
	C_aen = collections.Counter(aen_day)

	# AEN sent to infected individuals
	iagent_receive_aen_day = compressMany(aen_day, [(x != 'Recovered' and x != 'Uninfected') for x in aen_is])
	C_aeni = collections.Counter(iagent_receive_aen_day)
	##

	## Tests
	C_tests = collections.Counter(test_day)
	
	# Positive test results
	trp_day = compressMany(testResult_day, [x == True for x in testResult_positive])
	C_trp = collections.Counter(trp_day)

	# Negative test results
	trn_day = compressMany(testResult_day, [x == False for x in testResult_positive])
	C_trn = collections.Counter(trn_day)
	##

	## Calls
	# Number of calls
	C_calls = collections.Counter(call_day)

	# Number of successful calls
	successful_calls_day = compressMany(call_day, [x == True for x in call_success])
	C_scalls = collections.Counter(successful_calls_day)

	# Number of additions to call list
	C_atcl = collections.Counter(added_day)

	# Number of drops from call list
	C_dfcl = collections.Counter(dropped_day)
	##

	print('     Form arrays')
	for n, day in enumerate(days):
		new_cases[n] = C_nc[day]
		new_infected_cases[n] = C_nic[day]
		recovered_cases[n] = C_recovery[day]
		removed_cases[n] = C_rem[day]
		flashes[n] = C_flash[day]
		keyUploads[n] = C_ku[day]
		aen[n] = C_aen[day]
		aeni[n] = C_aeni[day]
		tests[n] = C_tests[day]
		positive_test_results[n] = C_trp[day]
		negative_test_results[n] = C_trn[day]
		calls[n] = C_calls[day]
		successful_calls[n] = C_scalls[day]
		dropped_from_call_list[n] = C_dfcl[day]
		additions_to_call_list[n] = C_atcl[day]

	out = { \
	'day': days,
	'new_cases': new_cases,
	'new_infected_cases': new_infected_cases,
	'recovered_cases': recovered_cases,
	'removed_cases': removed_cases,
	'flashes': flashes,
	'keyUploads': keyUploads,
	'aen': aen,
	'aen_sent_to_infected_individuals': aeni,
	'tests': tests,
	'positive_test_results': positive_test_results,
	'negative_test_results': negative_test_results,
	'calls': calls,
	'dropped_from_call_list': dropped_from_call_list,
	'successful_calls': successful_calls,
	'additions_to_call_list': additions_to_call_list}

	return out

def compressMany(inputList, *args):
	
	cond = args[0]
	if len(args) > 1:
		for arg in args[1:]:			
			cond = np.logical_and(cond, arg)

	out = list(compress(inputList, cond))
	return out

def getPeople(events, last_day):

	# Get number of generation events
	N = len(events['generation'])

	# Extract relevant fields
	flds = ['day', 'generator', 'individual', 'infectionStatus', 'wearingMask', 'generatorWearingMask', 'behavior', 'hasApp', 'generatorHasApp', 'falseDiscovery', 'latentPeriod', 'incubationPeriod']
	(first_day, generator, individual, infectionStatus, wearingMaskAtStart, generatorWearingMask, behaviorAtStart, hasApp, generatorHasApp, falseDiscovery, latentPeriod, incubationPeriod) = exf(events['generation'], flds)

	# Assert that list of individuals can serve as an index list as well.  It must start at one and increase by 1 in every step
	if (not all(np.diff(individual) == 1)) or individual[0] != 1:
		raise Exception('Cannot use this list of individuals as an index list.')

	# OUTPUT: Express behavior at start as a number.  Normal = 0, Minimal = 1, Moderate = 2, Maximal = 3
	behaviorAtStartNum = [0] * N
	for nb, startingBehavior in enumerate(behaviorAtStart):
		if startingBehavior == 'Normal':
			behaviorAtStartNum[nb] = 0
		elif startingBehavior == 'maximal_restriction':
			behaviorAtStartNum[nb] = 3
		elif startingBehavior == 'moderate_restriction':
			behaviorAtStartNum[nb] = 2
		elif startingBehavior == 'minimal_restriction':
			behaviorAtStartNum[nb] = 1
		else:
			raise Exception('Invalid starting behavior %s' % startingBehavior)

	# OUTPUT: Get whether infected or not
	print('     Get infection status')
	infected = [False if x=='Uninfected' else True for x in infectionStatus]

	# OUTPUT: Get whether recovered or not
	print('     Get recovery status')
	recovered_individuals = [i['individual'] for i in events['infectionStatusChange'] if i['infectionStatus']=='Recovered']
	recovered = boolIndividual(recovered_individuals, N)
	
	# OUTPUT: Get whether removed or not
	print('     Get removed status')
	(rem_ind,) = exf(events['removal'], ['individual'])
	removed = boolIndividual(rem_ind, N)

	# OUTPUT: Get number of descendants and number of infected descendants
	print('     Get number of descendants')
	C = collections.Counter(generator) # get counter dictionary
	genInds = list(C.keys()) # get individuals who are a generator
	nd = [0] * N
	for genInd in genInds:
		if genInd != None:
			nd[genInd - 1] = C[genInd]	

	# OUTPUT: Get number of infected descendants
	print('     Get number of infected descendants')
	infectionGenerators = list(compress(generator, infected)) # filter generators to just infection events
	Ci = collections.Counter(infectionGenerators) # get counter dictionary
	iGenInds = list(Ci.keys()) # get individuals who generated infected individuals
	nid = [0] * N
	for iGenInd in iGenInds:
		if iGenInd != None:
			nid[iGenInd - 1] = Ci[iGenInd]
	
	# OUTPUT: Get last day in sim
	print('     Get last day in sim')
	last_day = [last_day] * N
	for remEvent in events['removal']:
		last_day[remEvent['individual'] - 1] = remEvent['day']

	## AEN
	# OUTPUT: Get whether received AEN
	print('     Get AEN Bool')
	(aen_ind,) = exf(events['aen'], ['individual'])
	aen = boolIndividual(aen_ind, N)

	# OUTPUT: Get number of AENs received
	print('    Get AEN number')
	C_aen = collections.Counter(aen_ind)
	iAENs = list(C_aen.keys())
	aen_num = [0] * N
	for iAEN in iAENs:
		if iAEN != None:
			aen_num[iAEN - 1] = C_aen[iAEN]	
	##
	
	# OUTPUT: Get whether memory limit reached
	print('     Get whether memory limit reached')
	(memory_ind,) = exf(events['memoryLimitReached'], ['individual'])
	memoryLimitReached = boolIndividual(memory_ind, N)

	# OUTPUT: Get whether uploaded keys
	print('     Get whether uploaded keys')
	(upload_ind,) = exf(events['keyUpload'], ['individual'])
	keyUpload = boolIndividual(upload_ind, N)

	# OUTPUT: Get whether ID'd through manual contact tracing as contact or whether ID'd someone else through manual contact tracing (index)
	print('     Get MCT')
	(mctContact_ind, mctIndex_ind) = exf(events['identifiedContact'], ['contact', 'individual'])
	
	mctContact = boolIndividual(mctContact_ind, N)
	mctIndex = boolIndividual(mctIndex_ind, N)
	
	# OUTPUT: Get whether quarantined
	print('     Get quarantined')
	(bc_ind, bcs) = exf(events['behaviorChange'], ['individual', 'behavior'])
	
	quarBool = [False] * len(bcs)
	q = 0
	for bc in bcs:
		if bc in ['maximal_restriction', 'minimal_restriction', 'moderate_restriction']:
			quarBool[q] = True
		q += 1
	quarInds = list(compress(bc_ind, quarBool))
	quar = boolIndividual(quarInds, N)	

	# OUTPUT: Get whether tested and whether took multiple tests
	print('     Get testing')
	(tested_ind,) = exf(events['tookTest'], ['individual'])
	tested = boolIndividual(tested_ind, N)
	
	Ct = collections.Counter(tested_ind)
	multiTest_inds = [k for k, v in Ct.items() if v > 1]
	multipleTests = boolIndividual(multiTest_inds, N)

	# OUTPUT: Get whether received test result and if it is positive
	(testResult_ind, testResult_result) = exf(events['receivedTestResult'], ['individual', 'testResultPositive'])
	testResultReceived = boolIndividual(testResult_ind, N)

	positiveInds = list(compress(testResult_ind, testResult_result))
	testResultPositiveReceived = boolIndividual(positiveInds, N)

	# OUTPUT: Get whether individual put on a mask
	print('     Get mask use')
	(putOnMask_ind,) = exf(events['putOnMask'], ['individual'])
	putOnMask = boolIndividual(putOnMask_ind, N)

	## Calls
	print('     Get call list')
	# OUTPUT: Get whether individual dropped from call list
	(droppedFromCallList_ind,) = exf(events['droppedFromCallList'], ['individual'])
	droppedFromCallList = boolIndividual(droppedFromCallList_ind, N)

	# OUTPUT: Get whether individual called by public health
	(calledByPH_ind, call_success) = exf(events['publicHealthCall'], ['individual', 'success'])
	calledByPH = boolIndividual(calledByPH_ind, N)

	# OUTPUT: Get whether individual successfully called by public health
	calledByPHSuccess_ind = list(compress(calledByPH_ind, call_success))
	calledByPHSuccess = boolIndividual(calledByPHSuccess_ind, N)
	##

	# ASSEMBLE OUTPUT
	print('     Assemble output')

	people = { \
	'individual': individual,    
	'generator': generator,
	'infected': infected,
	'latentPeriod': latentPeriod,
	'incubationPeriod': incubationPeriod,
	'recovered': recovered,
	'removed': removed,
	'num_descendants': nd,
	'num_infected_descendants': nid,    
	'hasApp': hasApp,
	'generatorHasApp': generatorHasApp,
	'falseDiscovery': falseDiscovery,
	'wearingMaskAtStart': wearingMaskAtStart,
	'generatorWearingMask': generatorWearingMask,
	'putOnMask': putOnMask,
	'behaviorAtStart': behaviorAtStartNum,		
	'first_day': first_day,
	'last_day': last_day,
	'aen': aen,
	'aen_num': aen_num,
	'memoryLimitReached': memoryLimitReached,
	'keyUpload': keyUpload,
	'mctContact': mctContact,
	'mctIndex': mctIndex,
	'droppedFromCallList': droppedFromCallList,
	'calledByPH': calledByPH,
	'calledByPHSuccess': calledByPHSuccess,
	'quar': quar,
	'tested': tested,
	'testResultReceived': testResultReceived,
	'testResultPositiveReceived': testResultPositiveReceived,
	'multipleTests': multipleTests}

	return people

def boolIndividual(smallInd, N):	
	out = [False] * N
	for ind in smallInd:
		out[ind - 1] = True # smallInd consists of Individual ID numbers.  Must subtract 1 to get Python list index.
	return out

def exf(dictionary, keys):
	res = ()
	for key in keys:
		res = res + ([ev[key] for ev in dictionary],)
	return res
