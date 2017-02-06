#!/usr/bin/env python
import boto3, requests, sys
from retrying import retry

component = sys.argv[1]
max_retries = 120
delay = 5000

tag_keys = {
  'author-dispatcher': ['AuthorHost'],
  'publish-dispatcher': ['PublishHost'],
  'publish': ['PublishDispatcherHost']
}

def get_instance_id():
  response = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
  instance_id = response.text
  print 'Instance ID: {0}'.format(instance_id)
  return instance_id

@retry(stop_max_attempt_number=max_retries, wait_fixed=delay)
def wait_for_tag(tag_key, instance_id):
  print 'Checking existence of tag {0}'.format(tag_key)
  ec2 = boto3.resource('ec2')
  instance = ec2.Instance(instance_id)
  for tag in instance.tags:
    if tag['Key'] == tag_key:
      print 'Tag {0} exists with value {1}'.format(tag_key, tag['Value'])
      return True
  print 'Tag {0} does not exist'.format(tag_key)
  raise IOError('Tag {0} does not exist after {1} checks, giving up...'.format(tag_key, max_retries))

def main():
  if (tag_keys.has_key(component)):
    instance_id = get_instance_id()
    for tag_key in tag_keys[component]:
      wait_for_tag(tag_key, instance_id)
  else:
    print 'No tag to check for component {0}'.format(component)

main()
