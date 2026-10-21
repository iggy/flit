// This is a generated file - do not edit.
//
// Generated from flit/v1/cron.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/timestamp.pbjson.dart'
    as $0;

@$core.Deprecated('Use cronAskDescriptor instead')
const CronAsk$json = {
  '1': 'CronAsk',
  '2': [
    {'1': 'CRON_ASK_UNSPECIFIED', '2': 0},
    {'1': 'CRON_ASK_DENY', '2': 1},
    {'1': 'CRON_ASK_WAIT', '2': 2},
  ],
};

/// Descriptor for `CronAsk`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cronAskDescriptor = $convert.base64Decode(
    'CgdDcm9uQXNrEhgKFENST05fQVNLX1VOU1BFQ0lGSUVEEAASEQoNQ1JPTl9BU0tfREVOWRABEh'
    'EKDUNST05fQVNLX1dBSVQQAg==');

@$core.Deprecated('Use cronRunStateDescriptor instead')
const CronRunState$json = {
  '1': 'CronRunState',
  '2': [
    {'1': 'CRON_RUN_STATE_UNSPECIFIED', '2': 0},
    {'1': 'CRON_RUN_STATE_RUNNING', '2': 1},
    {'1': 'CRON_RUN_STATE_OK', '2': 2},
    {'1': 'CRON_RUN_STATE_NEEDS_ATTENTION', '2': 3},
    {'1': 'CRON_RUN_STATE_FAILED', '2': 4},
    {'1': 'CRON_RUN_STATE_SKIPPED', '2': 5},
  ],
};

/// Descriptor for `CronRunState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cronRunStateDescriptor = $convert.base64Decode(
    'CgxDcm9uUnVuU3RhdGUSHgoaQ1JPTl9SVU5fU1RBVEVfVU5TUEVDSUZJRUQQABIaChZDUk9OX1'
    'JVTl9TVEFURV9SVU5OSU5HEAESFQoRQ1JPTl9SVU5fU1RBVEVfT0sQAhIiCh5DUk9OX1JVTl9T'
    'VEFURV9ORUVEU19BVFRFTlRJT04QAxIZChVDUk9OX1JVTl9TVEFURV9GQUlMRUQQBBIaChZDUk'
    '9OX1JVTl9TVEFURV9TS0lQUEVEEAU=');

@$core.Deprecated('Use cronTriggerDescriptor instead')
const CronTrigger$json = {
  '1': 'CronTrigger',
  '2': [
    {'1': 'CRON_TRIGGER_UNSPECIFIED', '2': 0},
    {'1': 'CRON_TRIGGER_SCHEDULE', '2': 1},
    {'1': 'CRON_TRIGGER_CATCH_UP', '2': 2},
    {'1': 'CRON_TRIGGER_MANUAL', '2': 3},
  ],
};

/// Descriptor for `CronTrigger`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cronTriggerDescriptor = $convert.base64Decode(
    'CgtDcm9uVHJpZ2dlchIcChhDUk9OX1RSSUdHRVJfVU5TUEVDSUZJRUQQABIZChVDUk9OX1RSSU'
    'dHRVJfU0NIRURVTEUQARIZChVDUk9OX1RSSUdHRVJfQ0FUQ0hfVVAQAhIXChNDUk9OX1RSSUdH'
    'RVJfTUFOVUFMEAM=');

@$core.Deprecated('Use cronJobDescriptor instead')
const CronJob$json = {
  '1': 'CronJob',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'schedule', '3': 2, '4': 1, '5': 9, '10': 'schedule'},
    {'1': 'schedule_text', '3': 3, '4': 1, '5': 9, '10': 'scheduleText'},
    {'1': 'one_shot', '3': 4, '4': 1, '5': 8, '10': 'oneShot'},
    {'1': 'enabled', '3': 5, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'project_id', '3': 6, '4': 1, '5': 9, '10': 'projectId'},
    {'1': 'project_name', '3': 7, '4': 1, '5': 9, '10': 'projectName'},
    {'1': 'dir', '3': 8, '4': 1, '5': 9, '10': 'dir'},
    {'1': 'role', '3': 9, '4': 1, '5': 9, '10': 'role'},
    {'1': 'provider', '3': 10, '4': 1, '5': 9, '10': 'provider'},
    {'1': 'model', '3': 11, '4': 1, '5': 9, '10': 'model'},
    {'1': 'effort', '3': 12, '4': 1, '5': 9, '10': 'effort'},
    {
      '1': 'ask',
      '3': 13,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.CronAsk',
      '10': 'ask'
    },
    {
      '1': 'ask_timeout_seconds',
      '3': 14,
      '4': 1,
      '5': 3,
      '10': 'askTimeoutSeconds'
    },
    {'1': 'yolo', '3': 15, '4': 1, '5': 8, '10': 'yolo'},
    {'1': 'timezone', '3': 16, '4': 1, '5': 9, '10': 'timezone'},
    {'1': 'prompt', '3': 17, '4': 1, '5': 9, '10': 'prompt'},
    {'1': 'path', '3': 18, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'next_run_time',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'nextRunTime'
    },
    {
      '1': 'last_run',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.flit.v1.CronRun',
      '10': 'lastRun'
    },
    {'1': 'error', '3': 21, '4': 1, '5': 9, '10': 'error'},
    {
      '1': 'running_session_id',
      '3': 22,
      '4': 1,
      '5': 9,
      '10': 'runningSessionId'
    },
  ],
};

/// Descriptor for `CronJob`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cronJobDescriptor = $convert.base64Decode(
    'CgdDcm9uSm9iEhIKBG5hbWUYASABKAlSBG5hbWUSGgoIc2NoZWR1bGUYAiABKAlSCHNjaGVkdW'
    'xlEiMKDXNjaGVkdWxlX3RleHQYAyABKAlSDHNjaGVkdWxlVGV4dBIZCghvbmVfc2hvdBgEIAEo'
    'CFIHb25lU2hvdBIYCgdlbmFibGVkGAUgASgIUgdlbmFibGVkEh0KCnByb2plY3RfaWQYBiABKA'
    'lSCXByb2plY3RJZBIhCgxwcm9qZWN0X25hbWUYByABKAlSC3Byb2plY3ROYW1lEhAKA2RpchgI'
    'IAEoCVIDZGlyEhIKBHJvbGUYCSABKAlSBHJvbGUSGgoIcHJvdmlkZXIYCiABKAlSCHByb3ZpZG'
    'VyEhQKBW1vZGVsGAsgASgJUgVtb2RlbBIWCgZlZmZvcnQYDCABKAlSBmVmZm9ydBIiCgNhc2sY'
    'DSABKA4yEC5mbGl0LnYxLkNyb25Bc2tSA2FzaxIuChNhc2tfdGltZW91dF9zZWNvbmRzGA4gAS'
    'gDUhFhc2tUaW1lb3V0U2Vjb25kcxISCgR5b2xvGA8gASgIUgR5b2xvEhoKCHRpbWV6b25lGBAg'
    'ASgJUgh0aW1lem9uZRIWCgZwcm9tcHQYESABKAlSBnByb21wdBISCgRwYXRoGBIgASgJUgRwYX'
    'RoEj4KDW5leHRfcnVuX3RpbWUYEyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgtu'
    'ZXh0UnVuVGltZRIrCghsYXN0X3J1bhgUIAEoCzIQLmZsaXQudjEuQ3JvblJ1blIHbGFzdFJ1bh'
    'IUCgVlcnJvchgVIAEoCVIFZXJyb3ISLAoScnVubmluZ19zZXNzaW9uX2lkGBYgASgJUhBydW5u'
    'aW5nU2Vzc2lvbklk');

@$core.Deprecated('Use cronRunDescriptor instead')
const CronRun$json = {
  '1': 'CronRun',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'job', '3': 2, '4': 1, '5': 9, '10': 'job'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {
      '1': 'state',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.CronRunState',
      '10': 'state'
    },
    {
      '1': 'trigger',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.flit.v1.CronTrigger',
      '10': 'trigger'
    },
    {
      '1': 'scheduled_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'scheduledTime'
    },
    {
      '1': 'start_time',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    {
      '1': 'finish_time',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'finishTime'
    },
    {'1': 'summary', '3': 9, '4': 1, '5': 9, '10': 'summary'},
    {'1': 'refused_commands', '3': 10, '4': 3, '5': 9, '10': 'refusedCommands'},
    {'1': 'quiet', '3': 11, '4': 1, '5': 8, '10': 'quiet'},
  ],
};

/// Descriptor for `CronRun`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cronRunDescriptor = $convert.base64Decode(
    'CgdDcm9uUnVuEg4KAmlkGAEgASgJUgJpZBIQCgNqb2IYAiABKAlSA2pvYhIdCgpzZXNzaW9uX2'
    'lkGAMgASgJUglzZXNzaW9uSWQSKwoFc3RhdGUYBCABKA4yFS5mbGl0LnYxLkNyb25SdW5TdGF0'
    'ZVIFc3RhdGUSLgoHdHJpZ2dlchgFIAEoDjIULmZsaXQudjEuQ3JvblRyaWdnZXJSB3RyaWdnZX'
    'ISQQoOc2NoZWR1bGVkX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg1z'
    'Y2hlZHVsZWRUaW1lEjkKCnN0YXJ0X3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZX'
    'N0YW1wUglzdGFydFRpbWUSOwoLZmluaXNoX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYu'
    'VGltZXN0YW1wUgpmaW5pc2hUaW1lEhgKB3N1bW1hcnkYCSABKAlSB3N1bW1hcnkSKQoQcmVmdX'
    'NlZF9jb21tYW5kcxgKIAMoCVIPcmVmdXNlZENvbW1hbmRzEhQKBXF1aWV0GAsgASgIUgVxdWll'
    'dA==');

@$core.Deprecated('Use listCronJobsRequestDescriptor instead')
const ListCronJobsRequest$json = {
  '1': 'ListCronJobsRequest',
};

/// Descriptor for `ListCronJobsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCronJobsRequestDescriptor =
    $convert.base64Decode('ChNMaXN0Q3JvbkpvYnNSZXF1ZXN0');

@$core.Deprecated('Use listCronJobsResponseDescriptor instead')
const ListCronJobsResponse$json = {
  '1': 'ListCronJobsResponse',
  '2': [
    {
      '1': 'jobs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.CronJob',
      '10': 'jobs'
    },
    {'1': 'dir', '3': 2, '4': 1, '5': 9, '10': 'dir'},
  ],
};

/// Descriptor for `ListCronJobsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCronJobsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0Q3JvbkpvYnNSZXNwb25zZRIkCgRqb2JzGAEgAygLMhAuZmxpdC52MS5Dcm9uSm9iUg'
    'Rqb2JzEhAKA2RpchgCIAEoCVIDZGly');

@$core.Deprecated('Use getCronJobRequestDescriptor instead')
const GetCronJobRequest$json = {
  '1': 'GetCronJobRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `GetCronJobRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCronJobRequestDescriptor = $convert
    .base64Decode('ChFHZXRDcm9uSm9iUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1l');

@$core.Deprecated('Use getCronJobResponseDescriptor instead')
const GetCronJobResponse$json = {
  '1': 'GetCronJobResponse',
  '2': [
    {'1': 'job', '3': 1, '4': 1, '5': 11, '6': '.flit.v1.CronJob', '10': 'job'},
  ],
};

/// Descriptor for `GetCronJobResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCronJobResponseDescriptor = $convert.base64Decode(
    'ChJHZXRDcm9uSm9iUmVzcG9uc2USIgoDam9iGAEgASgLMhAuZmxpdC52MS5Dcm9uSm9iUgNqb2'
    'I=');

@$core.Deprecated('Use runCronJobRequestDescriptor instead')
const RunCronJobRequest$json = {
  '1': 'RunCronJobRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `RunCronJobRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runCronJobRequestDescriptor = $convert
    .base64Decode('ChFSdW5Dcm9uSm9iUmVxdWVzdBISCgRuYW1lGAEgASgJUgRuYW1l');

@$core.Deprecated('Use runCronJobResponseDescriptor instead')
const RunCronJobResponse$json = {
  '1': 'RunCronJobResponse',
  '2': [
    {'1': 'run', '3': 1, '4': 1, '5': 11, '6': '.flit.v1.CronRun', '10': 'run'},
  ],
};

/// Descriptor for `RunCronJobResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runCronJobResponseDescriptor = $convert.base64Decode(
    'ChJSdW5Dcm9uSm9iUmVzcG9uc2USIgoDcnVuGAEgASgLMhAuZmxpdC52MS5Dcm9uUnVuUgNydW'
    '4=');

@$core.Deprecated('Use setCronJobEnabledRequestDescriptor instead')
const SetCronJobEnabledRequest$json = {
  '1': 'SetCronJobEnabledRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SetCronJobEnabledRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setCronJobEnabledRequestDescriptor =
    $convert.base64Decode(
        'ChhTZXRDcm9uSm9iRW5hYmxlZFJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgdlbmFibG'
        'VkGAIgASgIUgdlbmFibGVk');

@$core.Deprecated('Use setCronJobEnabledResponseDescriptor instead')
const SetCronJobEnabledResponse$json = {
  '1': 'SetCronJobEnabledResponse',
  '2': [
    {'1': 'job', '3': 1, '4': 1, '5': 11, '6': '.flit.v1.CronJob', '10': 'job'},
  ],
};

/// Descriptor for `SetCronJobEnabledResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setCronJobEnabledResponseDescriptor =
    $convert.base64Decode(
        'ChlTZXRDcm9uSm9iRW5hYmxlZFJlc3BvbnNlEiIKA2pvYhgBIAEoCzIQLmZsaXQudjEuQ3Jvbk'
        'pvYlIDam9i');

@$core.Deprecated('Use listCronRunsRequestDescriptor instead')
const ListCronRunsRequest$json = {
  '1': 'ListCronRunsRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListCronRunsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCronRunsRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0Q3JvblJ1bnNSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUSGwoJcGFnZV9zaXplGA'
    'IgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rva2VuGAMgASgJUglwYWdlVG9rZW4=');

@$core.Deprecated('Use listCronRunsResponseDescriptor instead')
const ListCronRunsResponse$json = {
  '1': 'ListCronRunsResponse',
  '2': [
    {
      '1': 'runs',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.flit.v1.CronRun',
      '10': 'runs'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListCronRunsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCronRunsResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0Q3JvblJ1bnNSZXNwb25zZRIkCgRydW5zGAEgAygLMhAuZmxpdC52MS5Dcm9uUnVuUg'
    'RydW5zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbg==');

const $core.Map<$core.String, $core.dynamic> CronServiceBase$json = {
  '1': 'CronService',
  '2': [
    {
      '1': 'ListCronJobs',
      '2': '.flit.v1.ListCronJobsRequest',
      '3': '.flit.v1.ListCronJobsResponse',
      '4': {'34': 1},
    },
    {
      '1': 'GetCronJob',
      '2': '.flit.v1.GetCronJobRequest',
      '3': '.flit.v1.GetCronJobResponse',
      '4': {'34': 1},
    },
    {
      '1': 'RunCronJob',
      '2': '.flit.v1.RunCronJobRequest',
      '3': '.flit.v1.RunCronJobResponse'
    },
    {
      '1': 'SetCronJobEnabled',
      '2': '.flit.v1.SetCronJobEnabledRequest',
      '3': '.flit.v1.SetCronJobEnabledResponse'
    },
    {
      '1': 'ListCronRuns',
      '2': '.flit.v1.ListCronRunsRequest',
      '3': '.flit.v1.ListCronRunsResponse',
      '4': {'34': 1},
    },
  ],
};

@$core.Deprecated('Use cronServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    CronServiceBase$messageJson = {
  '.flit.v1.ListCronJobsRequest': ListCronJobsRequest$json,
  '.flit.v1.ListCronJobsResponse': ListCronJobsResponse$json,
  '.flit.v1.CronJob': CronJob$json,
  '.google.protobuf.Timestamp': $0.Timestamp$json,
  '.flit.v1.CronRun': CronRun$json,
  '.flit.v1.GetCronJobRequest': GetCronJobRequest$json,
  '.flit.v1.GetCronJobResponse': GetCronJobResponse$json,
  '.flit.v1.RunCronJobRequest': RunCronJobRequest$json,
  '.flit.v1.RunCronJobResponse': RunCronJobResponse$json,
  '.flit.v1.SetCronJobEnabledRequest': SetCronJobEnabledRequest$json,
  '.flit.v1.SetCronJobEnabledResponse': SetCronJobEnabledResponse$json,
  '.flit.v1.ListCronRunsRequest': ListCronRunsRequest$json,
  '.flit.v1.ListCronRunsResponse': ListCronRunsResponse$json,
};

/// Descriptor for `CronService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List cronServiceDescriptor = $convert.base64Decode(
    'CgtDcm9uU2VydmljZRJQCgxMaXN0Q3JvbkpvYnMSHC5mbGl0LnYxLkxpc3RDcm9uSm9ic1JlcX'
    'Vlc3QaHS5mbGl0LnYxLkxpc3RDcm9uSm9ic1Jlc3BvbnNlIgOQAgESSgoKR2V0Q3JvbkpvYhIa'
    'LmZsaXQudjEuR2V0Q3JvbkpvYlJlcXVlc3QaGy5mbGl0LnYxLkdldENyb25Kb2JSZXNwb25zZS'
    'IDkAIBEkUKClJ1bkNyb25Kb2ISGi5mbGl0LnYxLlJ1bkNyb25Kb2JSZXF1ZXN0GhsuZmxpdC52'
    'MS5SdW5Dcm9uSm9iUmVzcG9uc2USWgoRU2V0Q3JvbkpvYkVuYWJsZWQSIS5mbGl0LnYxLlNldE'
    'Nyb25Kb2JFbmFibGVkUmVxdWVzdBoiLmZsaXQudjEuU2V0Q3JvbkpvYkVuYWJsZWRSZXNwb25z'
    'ZRJQCgxMaXN0Q3JvblJ1bnMSHC5mbGl0LnYxLkxpc3RDcm9uUnVuc1JlcXVlc3QaHS5mbGl0Ln'
    'YxLkxpc3RDcm9uUnVuc1Jlc3BvbnNlIgOQAgE=');
