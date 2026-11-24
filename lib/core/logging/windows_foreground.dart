import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Win32 helpers that bring a folder window opened by the shell to the front.
///
/// The folder window belongs to the already running `explorer.exe` (the
/// shell), which has no foreground rights, so Windows opens it behind the app.
/// The app still owns the foreground right after the click, so it may hand it
/// over with `SetForegroundWindow`. Every call is best-effort: failures leave
/// the window where Windows put it.
abstract final class WindowsForeground {
  static const _explorerWindowClass = 'CabinetWClass';
  static const _asfwAny = 0xFFFFFFFF;
  static const _swShow = 5;
  static const _swRestore = 9;

  static DynamicLibrary? _user32Cache;
  static DynamicLibrary get _user32 =>
      _user32Cache ??= DynamicLibrary.open('user32.dll');

  /// Lets any process take the foreground (`AllowSetForegroundWindow`).
  static void allowAnyProcessToSetForeground() {
    try {
      _user32.lookupFunction<Int32 Function(Uint32), int Function(int)>(
        'AllowSetForegroundWindow',
      )(_asfwAny);
    } catch (_) {
      // Best-effort; see class docs.
    }
  }

  /// Waits up to [timeout] for the File Explorer window showing [folderPath]
  /// and brings it to the front. Returns whether one was focused.
  ///
  /// Matches by title (the folder name, or the full path when Explorer is set
  /// to show it) instead of "windows that did not exist before": Windows 11
  /// may reuse a preloaded hidden Explorer window that already existed.
  static Future<bool> focusExplorerWindowFor(
    String folderPath, {
    Duration timeout = const Duration(seconds: 3),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    try {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(interval);
        final hwnd = _findExplorerWindowFor(folderPath);
        if (hwnd != 0) {
          _bringToFront(hwnd);
          return true;
        }
      }
    } catch (_) {
      // Best-effort; see class docs.
    }
    return false;
  }

  /// Whether an Explorer window [title] belongs to [folderPath].
  @visibleForTesting
  static bool titleMatches(String title, String folderPath) {
    final path = _trimSeparators(folderPath).toLowerCase();
    final name = path.split(RegExp(r'[\\/]')).last;
    final t = title.trim().toLowerCase();
    if (name.isEmpty || t.isEmpty) return false;
    // "logs", "logs - File Explorer" (localized suffix) or the full path.
    return t == name || t.startsWith('$name - ') || t.startsWith(path);
  }

  static String _trimSeparators(String path) =>
      path.replaceAll(RegExp(r'[\\/]+$'), '');

  static int _findExplorerWindowFor(String folderPath) {
    final findWindowEx = _user32
        .lookupFunction<
          IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
          int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)
        >('FindWindowExW');
    final getWindowText = _user32
        .lookupFunction<
          Int32 Function(IntPtr, Pointer<Utf16>, Int32),
          int Function(int, Pointer<Utf16>, int)
        >('GetWindowTextW');
    const bufferChars = 1024;
    final className = _explorerWindowClass.toNativeUtf16();
    final buffer = calloc<Uint16>(bufferChars).cast<Utf16>();
    try {
      var hwnd = 0;
      // Bounded loop: a handful of Explorer windows at most.
      for (var i = 0; i < 256; i++) {
        hwnd = findWindowEx(0, hwnd, className, nullptr);
        if (hwnd == 0) return 0;
        final length = getWindowText(hwnd, buffer, bufferChars);
        if (length > 0 && titleMatches(buffer.toDartString(), folderPath)) {
          return hwnd;
        }
      }
      return 0;
    } finally {
      malloc.free(className);
      calloc.free(buffer);
    }
  }

  static void _bringToFront(int hwnd) {
    final isIconic = _user32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsIconic');
    final showWindow = _user32
        .lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>(
          'ShowWindow',
        );
    final bringWindowToTop = _user32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'BringWindowToTop',
        );
    final setForegroundWindow = _user32
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'SetForegroundWindow',
        );
    showWindow(hwnd, isIconic(hwnd) != 0 ? _swRestore : _swShow);
    bringWindowToTop(hwnd);
    setForegroundWindow(hwnd);
  }
}
