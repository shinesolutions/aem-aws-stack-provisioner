#!/usr/bin/env python3
import boto3
from botocore.config import Config
import logging
import os
import sys
from socket import gethostname
from argparse import ArgumentParser
import textwrap

# setting up logger
logging.basicConfig(
    stream = sys.stdout,
    format = '%(asctime)s ' + gethostname() + ' %(levelname)-8s %(message)s',
    datefmt = "%Y-%m-%d %H:%M:%S"
    )
logger = logging.getLogger(__name__)
logger.setLevel(int(os.getenv('LOG_LEVEL', logging.INFO)))

client = boto3.client('logs')


def unwrap(txt):
    return ' '.join(textwrap.wrap(textwrap.dedent(txt).strip()))

def parse_args():
    p = ArgumentParser(
        description=unwrap("""
            Subscribe AWS CloudWatch Log groups to LAMBDA.
        """),
    )
    p.add_argument(
        '--stack_prefix',
        action  = 'store',
        default = '',
        metavar = 'StackABC',
        help    = unwrap("""
            The AEM StackPrefix.
        """),
    )
    p.add_argument(
        '--subscription_arn',
        action  = 'store',
        default = '',
        metavar = 'arn:aws:lambda:*:*:function:*',
        help    = unwrap("""
            The AWS Lambda ARN to subscribe the log groups to.
        """),
    )

    args = p.parse_args()
    return args

########################################################################
# Get all log groups of log groups beginning with 'stack_prefix/'
# and return a list of all found log groups
########################################################################
def get_log_groups(stack_prefix):
    log_groups = {}

    response = client.describe_log_groups(
        logGroupNamePrefix=stack_prefix + '/',
        limit=50
    )

    log_groups = response['logGroups']

    if 'nextToken' in response:
        while 'nextToken' in response:
            response = client.describe_log_groups(
                limit=50,
                nextToken=response['nextToken'],
                logGroupNamePrefix=stack_prefix + '/'
            )
            log_groups = log_groups + response['logGroups']
    logger.debug('Found log groups: ')
    logger.debug(log_groups)
    return log_groups

########################################################################
# Return a list of all log_groups
########################################################################
def get_log_group_names(stack_prefix):
    log_group_names = []

    log_groups = get_log_groups(stack_prefix)
    for log_group in log_groups:
        log_group_names.append(log_group['logGroupName'])

    logger.debug('Found log_groups: ')
    logger.debug(log_group_names)
    return log_group_names

########################################################################
# Return a list of the log group subscription filter
########################################################################
def get_subscribed_log_group(log_group_name):
    subscribed_log_group = {}

    response = client.describe_subscription_filters(
        logGroupName=log_group_name,
        limit=50
    )

    subscribed_log_group = response['subscriptionFilters']

    if 'nextToken' in response:
        while 'nextToken' in response:
            response = client.describe_subscription_filters(
                limit=50,
                nextToken=response['nextToken'],
                logGroupName=stack_prefix + '/'
            )

            subscribed_log_group = subscribed_log_group + response['logGroups']

    logger.debug('Found subscribed log groups: ')
    logger.debug(subscribed_log_group)
    return subscribed_log_group

########################################################################
# Subscribe the provided log group
########################################################################
def subscribe_log_group(log_group_name, subscription_arn):
    subscribed_log_group = {}


    subscribed_log_group = get_subscribed_log_group(log_group_name)

    if len(subscribed_log_group) < 1:

        client.put_subscription_filter(
            logGroupName=log_group_name,
            filterName=log_group_name + '_CW-S3_Stream',
            filterPattern='',
            destinationArn=subscription_arn
        )
        logger.info('Log group ' + log_group_name + ' successfully subscribed')

    else:
        logger.info('Skip log group ' + log_group_name + '. Loggroup already subscribed.')

if __name__ == '__main__':
    args = parse_args()
    stack_prefix = args.stack_prefix

    # Always append :prod alias of the lambda function
    subscription_arn = args.subscription_arn + ':prod'

    logger.debug('Stack Prefix: ')
    logger.debug(stack_prefix)
    logger.debug('Lambda subscription ARN: ')
    logger.debug(subscription_arn)

    logger.info('Get log group names')
    log_group_names = get_log_group_names(stack_prefix)

    if len(log_group_names) > 0:
        logger.info('Subscribe log groups to lambda function')
        for log_group_name in log_group_names:
            logger.debug('Subscribe log group: ' + log_group_name)
            subscribe_log_group(log_group_name, subscription_arn)
    else:
        logger.info('No loggroups for subscription found.')
        logger.info('Please check if stack name is correct.')
