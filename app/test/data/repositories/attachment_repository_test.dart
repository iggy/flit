// P7 acceptance: AttachmentRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/attachment_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call
/// and answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  /// Every (method, params) call, in order.
  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) async {
    calls.add((method: method, params: params));
    final answer = handler;
    return answer == null ? const <String, dynamic>{} : answer(method, params);
  }
}

void main() {
  group('AttachmentRepositoryImpl.attachImageBytes (wire image.attach_bytes)',
      () {
    test('sends image.attach_bytes with all params', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': true,
          'path': '/tmp/img_123.png',
          'count': 1,
          'name': 'photo.png',
          'width': 800,
          'height': 600,
          'bytes': 51200,
          'token_estimate': 1275,
          'text': '',
          'remainder': '',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.attachImageBytes(
        'sess_abc',
        contentBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAUA',
        filename: 'photo.png',
        ext: 'png',
      );

      expect(client.calls.single.method, 'image.attach_bytes');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'content_base64': 'iVBORw0KGgoAAAANSUhEUgAAAAUA',
        'filename': 'photo.png',
        'ext': 'png',
      });
      expect(result.path, '/tmp/img_123.png');
      expect(result.name, 'photo.png');
      expect(result.count, 1);
      expect(result.width, 800);
      expect(result.height, 600);
      expect(result.bytes, 51200);
      expect(result.tokenEstimate, 1275);
    });

    test('omits filename and ext when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'path': '/tmp/img_456.png',
          'count': 2,
          'name': 'image',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      await repository.attachImageBytes(
        'sess_abc',
        contentBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA',
      );

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'content_base64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA',
      });
    });

    test('handles absent optional fields (no PIL)', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'path': '/tmp/img_789.png',
          'count': 1,
          'name': 'screenshot.png',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.attachImageBytes(
        'sess_abc',
        contentBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAUA',
      );

      expect(result.path, '/tmp/img_789.png');
      expect(result.name, 'screenshot.png');
      expect(result.count, 1);
      expect(result.width, isNull);
      expect(result.height, isNull);
      expect(result.tokenEstimate, isNull);
    });
  });

  group('AttachmentRepositoryImpl.detachImage (wire image.detach)', () {
    test('sends image.detach with session_id and path', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'detached': true,
          'count': 0,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result =
          await repository.detachImage('sess_abc', '/tmp/img_123.png');

      expect(client.calls.single.method, 'image.detach');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'path': '/tmp/img_123.png',
      });
      expect(result.detached, true);
      expect(result.count, 0);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = AttachmentRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.detachImage('sess_abc', '/tmp/img.png');

      expect(result.detached, false);
      expect(result.count, 0);
    });
  });

  group('AttachmentRepositoryImpl.attachPdf (wire pdf.attach)', () {
    test('sends pdf.attach with all params', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': true,
          'filename': 'document.pdf',
          'pages_attached': 2,
          'pages': <Map<String, dynamic>>[
            <String, dynamic>{
              'path': '/tmp/pdf_123_p1.png',
              'page': 1,
              'name': 'document.pdf page 1',
              'width': 612,
              'height': 792,
              'token_estimate': 2000,
            },
            <String, dynamic>{
              'path': '/tmp/pdf_123_p2.png',
              'page': 2,
              'name': 'document.pdf page 2',
              'width': 612,
              'height': 792,
              'token_estimate': 1800,
            },
          ],
          'count': 2,
          'text': 'Extracted PDF text...',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.attachPdf(
        'sess_abc',
        contentBase64: 'JVBERi0xLjQK...',
        filename: 'document.pdf',
        firstPage: 1,
        lastPage: 2,
      );

      expect(client.calls.single.method, 'pdf.attach');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'content_base64': 'JVBERi0xLjQK...',
        'filename': 'document.pdf',
        'first_page': 1,
        'last_page': 2,
      });
      expect(result.filename, 'document.pdf');
      expect(result.pagesAttached, 2);
      expect(result.pages.length, 2);
      expect(result.pages[0].path, '/tmp/pdf_123_p1.png');
      expect(result.pages[0].name, 'document.pdf page 1');
      expect(result.pages[0].width, 612);
      expect(result.pages[0].height, 792);
      expect(result.pages[0].tokenEstimate, 2000);
      expect(result.pages[1].path, '/tmp/pdf_123_p2.png');
      expect(result.count, 2);
      expect(result.text, 'Extracted PDF text...');
    });

    test('omits optional params when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'filename': 'doc.pdf',
          'pages_attached': 1,
          'pages': <Map<String, dynamic>>[],
          'count': 1,
          'text': '',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      await repository.attachPdf(
        'sess_abc',
        contentBase64: 'JVBERi0xLjQK...',
      );

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'content_base64': 'JVBERi0xLjQK...',
      });
    });
  });

  group('AttachmentRepositoryImpl.attachFile (wire file.attach)', () {
    test('sends file.attach with data_url for remote', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': true,
          'name': 'data.csv',
          'path': '/tmp/file_123.csv',
          'ref_path': '@file:data.csv',
          'ref_text': '@file:data.csv',
          'uploaded': true,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.attachFile(
        'sess_abc',
        dataUrl: 'data:text/csv;base64,Y29sdW1uMSxjb2x1bW4yCg==',
        name: 'data.csv',
      );

      expect(client.calls.single.method, 'file.attach');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'data_url': 'data:text/csv;base64,Y29sdW1uMSxjb2x1bW4yCg==',
        'name': 'data.csv',
      });
      expect(result.name, 'data.csv');
      expect(result.path, '/tmp/file_123.csv');
      expect(result.refPath, '@file:data.csv');
      expect(result.refText, '@file:data.csv');
      expect(result.uploaded, true);
    });

    test('sends file.attach with path for loopback', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': true,
          'name': 'local.txt',
          'path': '/home/user/local.txt',
          'ref_path': '/home/user/local.txt',
          'ref_text': '@file:local.txt',
          'uploaded': false,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.attachFile(
        'sess_abc',
        path: '/home/user/local.txt',
      );

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'path': '/home/user/local.txt',
      });
      expect(result.name, 'local.txt');
      expect(result.uploaded, false);
    });
  });

  group('AttachmentRepositoryImpl.detectDrop (wire input.detect_drop)', () {
    test('sends input.detect_drop with session_id and text', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'matched': false,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.detectDrop('sess_abc', 'hello world');

      expect(client.calls.single.method, 'input.detect_drop');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
        'text': 'hello world',
      });
      expect(result.matched, false);
    });

    test('parses matched image case', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'matched': true,
          'is_image': true,
          'path': '/tmp/drop_123.png',
          'name': 'screenshot.png',
          'text': '',
          'count': 1,
          'width': 1920,
          'height': 1080,
          'token_estimate': 3000,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.detectDrop('sess_abc', '/path/to/img.png');

      expect(result.matched, true);
      expect(result.isImage, true);
      expect(result.path, '/tmp/drop_123.png');
      expect(result.name, 'screenshot.png');
      expect(result.image, isNotNull);
      expect(result.image!.path, '/tmp/drop_123.png');
      expect(result.image!.name, 'screenshot.png');
      expect(result.image!.count, 1);
      expect(result.image!.width, 1920);
      expect(result.image!.height, 1080);
      expect(result.image!.tokenEstimate, 3000);
    });

    test('parses matched file case', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'matched': true,
          'is_image': false,
          'path': '/tmp/file_456.txt',
          'name': 'notes.txt',
          'text': '',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.detectDrop('sess_abc', '/path/to/file.txt');

      expect(result.matched, true);
      expect(result.isImage, false);
      expect(result.path, '/tmp/file_456.txt');
      expect(result.name, 'notes.txt');
      expect(result.image, isNull);
    });

    test('parses not-matched case', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'matched': false,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.detectDrop('sess_abc', 'regular text');

      expect(result.matched, false);
      expect(result.isImage, false);
      expect(result.path, isNull);
      expect(result.name, isNull);
      expect(result.image, isNull);
    });
  });

  group('AttachmentRepositoryImpl.pasteClipboard (wire clipboard.paste)', () {
    test('sends clipboard.paste with session_id only', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': false,
          'message': 'No image in clipboard',
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.pasteClipboard('sess_abc');

      expect(client.calls.single.method, 'clipboard.paste');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_abc',
      });
      expect(result.attached, false);
      expect(result.message, 'No image in clipboard');
      expect(result.image, isNull);
    });

    test('parses attached image case', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'attached': true,
          'path': '/tmp/clipboard_789.png',
          'count': 1,
          'name': 'clipboard image',
          'width': 640,
          'height': 480,
          'token_estimate': 1200,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.pasteClipboard('sess_abc');

      expect(result.attached, true);
      expect(result.image, isNotNull);
      expect(result.image!.path, '/tmp/clipboard_789.png');
      expect(result.image!.name, 'clipboard image');
      expect(result.image!.count, 1);
      expect(result.image!.width, 640);
      expect(result.image!.height, 480);
      expect(result.image!.tokenEstimate, 1200);
    });
  });

  group('AttachmentRepositoryImpl.collapsePaste (wire paste.collapse)', () {
    test('sends paste.collapse with text only (NO session_id)', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'placeholder': '<large paste>',
          'path': '/tmp/paste_999.txt',
          'lines': 500,
        },
      );
      final repository = AttachmentRepositoryImpl(client);

      final result = await repository.collapsePaste('line1\nline2\n...\nline500');

      expect(client.calls.single.method, 'paste.collapse');
      expect(client.calls.single.params, <String, dynamic>{
        'text': 'line1\nline2\n...\nline500',
      });
      // CRITICAL: paste.collapse sends NO session_id
      expect(client.calls.single.params.containsKey('session_id'), false);
      expect(result.placeholder, '<large paste>');
      expect(result.path, '/tmp/paste_999.txt');
      expect(result.lines, 500);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = AttachmentRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.collapsePaste('text');

      expect(result.placeholder, '');
      expect(result.path, '');
      expect(result.lines, 0);
    });
  });
}
