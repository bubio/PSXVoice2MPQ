import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../../src/third_party/onnxruntime.g.dart';

/// The ONNX Runtime C API version the bindings were generated for
/// (`ORT_API_VERSION` in third_party/onnxruntime/onnxruntime_c_api.h).
const int _ortApiVersion = 23;

/// An error reported by ONNX Runtime.
final class OrtException implements Exception {
  final String message;

  const OrtException(this.message);

  @override
  String toString() => 'OrtException: $message';
}

/// A dense float32 tensor held in Dart memory.
final class FloatTensor {
  final Float32List data;
  final List<int> shape;

  FloatTensor(this.data, this.shape) {
    final expected = shape.fold<int>(1, (a, b) => a * b);
    if (expected != data.length) {
      throw ArgumentError(
        'Shape $shape needs $expected elements, got ${data.length}',
      );
    }
  }
}

/// Typed access to the parts of the `OrtApi` function table this app uses.
final class _Api {
  final Pointer<OrtApi> _p;

  _Api(this._p);

  OrtApi get _r => _p.ref;

  late final getErrorMessage = _r
      .GetErrorMessage.asFunction<Pointer<Char> Function(Pointer<OrtStatus>)>();
  late final releaseStatus =
      _r.ReleaseStatus.asFunction<void Function(Pointer<OrtStatus>)>();
  late final createEnv =
      _r.CreateEnv.asFunction<
        Pointer<OrtStatus> Function(
          int,
          Pointer<Char>,
          Pointer<Pointer<OrtEnv>>,
        )
      >();
  late final releaseEnv =
      _r.ReleaseEnv.asFunction<void Function(Pointer<OrtEnv>)>();
  late final createSessionOptions =
      _r.CreateSessionOptions.asFunction<
        Pointer<OrtStatus> Function(Pointer<Pointer<OrtSessionOptions>>)
      >();
  late final setIntraOpNumThreads =
      _r.SetIntraOpNumThreads.asFunction<
        Pointer<OrtStatus> Function(Pointer<OrtSessionOptions>, int)
      >();
  late final setGraphOptimizationLevel =
      _r.SetSessionGraphOptimizationLevel.asFunction<
        Pointer<OrtStatus> Function(Pointer<OrtSessionOptions>, int)
      >();
  late final releaseSessionOptions =
      _r.ReleaseSessionOptions.asFunction<
        void Function(Pointer<OrtSessionOptions>)
      >();
  late final createSession =
      _r.CreateSession.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtEnv>,
          Pointer<Char>,
          Pointer<OrtSessionOptions>,
          Pointer<Pointer<OrtSession>>,
        )
      >();
  late final releaseSession =
      _r.ReleaseSession.asFunction<void Function(Pointer<OrtSession>)>();
  late final createCpuMemoryInfo =
      _r.CreateCpuMemoryInfo.asFunction<
        Pointer<OrtStatus> Function(int, int, Pointer<Pointer<OrtMemoryInfo>>)
      >();
  late final releaseMemoryInfo =
      _r.ReleaseMemoryInfo.asFunction<void Function(Pointer<OrtMemoryInfo>)>();
  late final createTensorWithData =
      _r.CreateTensorWithDataAsOrtValue.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtMemoryInfo>,
          Pointer<Void>,
          int,
          Pointer<Int64>,
          int,
          int,
          Pointer<Pointer<OrtValue>>,
        )
      >();
  late final releaseValue =
      _r.ReleaseValue.asFunction<void Function(Pointer<OrtValue>)>();
  late final run =
      _r.Run.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtSession>,
          Pointer<OrtRunOptions>,
          Pointer<Pointer<Char>>,
          Pointer<Pointer<OrtValue>>,
          int,
          Pointer<Pointer<Char>>,
          int,
          Pointer<Pointer<OrtValue>>,
        )
      >();
  late final getTensorMutableData =
      _r.GetTensorMutableData.asFunction<
        Pointer<OrtStatus> Function(Pointer<OrtValue>, Pointer<Pointer<Void>>)
      >();
  late final getTensorTypeAndShape =
      _r.GetTensorTypeAndShape.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtValue>,
          Pointer<Pointer<OrtTensorTypeAndShapeInfo>>,
        )
      >();
  late final getDimensionsCount =
      _r.GetDimensionsCount.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtTensorTypeAndShapeInfo>,
          Pointer<Size>,
        )
      >();
  late final getDimensions =
      _r.GetDimensions.asFunction<
        Pointer<OrtStatus> Function(
          Pointer<OrtTensorTypeAndShapeInfo>,
          Pointer<Int64>,
          int,
        )
      >();
  late final releaseTensorTypeAndShapeInfo =
      _r.ReleaseTensorTypeAndShapeInfo.asFunction<
        void Function(Pointer<OrtTensorTypeAndShapeInfo>)
      >();
  late final createRunOptions =
      _r.CreateRunOptions.asFunction<
        Pointer<OrtStatus> Function(Pointer<Pointer<OrtRunOptions>>)
      >();
  late final runOptionsSetTerminate =
      _r.RunOptionsSetTerminate.asFunction<
        Pointer<OrtStatus> Function(Pointer<OrtRunOptions>)
      >();
  late final runOptionsUnsetTerminate =
      _r.RunOptionsUnsetTerminate.asFunction<
        Pointer<OrtStatus> Function(Pointer<OrtRunOptions>)
      >();
  late final releaseRunOptions =
      _r.ReleaseRunOptions.asFunction<void Function(Pointer<OrtRunOptions>)>();

  /// Throws [OrtException] if [status] reports an error, releasing it.
  void check(Pointer<OrtStatus> status) {
    if (status == nullptr) return;
    final message = getErrorMessage(status).cast<Utf8>().toDartString();
    releaseStatus(status);
    throw OrtException(message);
  }

  static _Api load(String libraryPath) {
    final bindings = OnnxRuntimeBindings(DynamicLibrary.open(libraryPath));
    final base = bindings.OrtGetApiBase();
    final getApi = base.ref.GetApi.asFunction<Pointer<OrtApi> Function(int)>();
    final api = getApi(_ortApiVersion);
    if (api == nullptr) {
      throw OrtException(
        'ONNX Runtime at $libraryPath does not support API version '
        '$_ortApiVersion',
      );
    }
    return _Api(api);
  }
}

/// An ONNX Runtime environment running models on the CPU.
///
/// Not thread-safe: use one instance per isolate. A run in progress can be
/// stopped from another isolate with [requestTerminate].
final class OnnxRuntime {
  final _Api _api;
  final Pointer<OrtEnv> _env;
  final Pointer<OrtMemoryInfo> _memoryInfo;
  final Pointer<OrtRunOptions> _runOptions;
  final int _threads;
  final List<OrtModel> _models = [];

  OnnxRuntime._(
    this._api,
    this._env,
    this._memoryInfo,
    this._runOptions,
    this._threads,
  );

  /// Loads the ONNX Runtime shared library at [libraryPath].
  ///
  /// [threads] is the intra-op thread count; 0 lets ONNX Runtime decide.
  factory OnnxRuntime.open(String libraryPath, {int threads = 0}) {
    final api = _Api.load(libraryPath);
    return using((arena) {
      final env = arena<Pointer<OrtEnv>>();
      api.check(
        api.createEnv(
          OrtLoggingLevel.ORT_LOGGING_LEVEL_WARNING.value,
          'psxvoice2mpq'.toNativeUtf8(allocator: arena).cast(),
          env,
        ),
      );
      final memoryInfo = arena<Pointer<OrtMemoryInfo>>();
      api.check(
        api.createCpuMemoryInfo(
          OrtAllocatorType.OrtArenaAllocator.value,
          OrtMemType.OrtMemTypeDefault.value,
          memoryInfo,
        ),
      );
      final runOptions = arena<Pointer<OrtRunOptions>>();
      api.check(api.createRunOptions(runOptions));
      return OnnxRuntime._(
        api,
        env.value,
        memoryInfo.value,
        runOptions.value,
        threads,
      );
    });
  }

  /// Address of the run options, for [requestTerminate] from another isolate.
  int get terminateHandle => _runOptions.address;

  /// Makes the run in progress (and later runs) on the runtime identified by
  /// [handle] fail with an [OrtException]. Safe to call from any isolate.
  static void requestTerminate(String libraryPath, int handle) {
    final api = _Api.load(libraryPath);
    api.check(
      api.runOptionsSetTerminate(Pointer<OrtRunOptions>.fromAddress(handle)),
    );
  }

  /// Clears a previous [requestTerminate].
  void resetTerminate() =>
      _api.check(_api.runOptionsUnsetTerminate(_runOptions));

  /// Loads the model file at [path].
  OrtModel loadModel(String path) {
    final session = using((arena) {
      final options = arena<Pointer<OrtSessionOptions>>();
      _api.check(_api.createSessionOptions(options));
      try {
        if (_threads > 0) {
          _api.check(_api.setIntraOpNumThreads(options.value, _threads));
        }
        _api.check(
          _api.setGraphOptimizationLevel(
            options.value,
            GraphOptimizationLevel.ORT_ENABLE_ALL.value,
          ),
        );
        // ORTCHAR_T is wchar_t (UTF-16) on Windows and char (UTF-8) elsewhere.
        final nativePath = Platform.isWindows
            ? path.toNativeUtf16(allocator: arena).cast<Char>()
            : path.toNativeUtf8(allocator: arena).cast<Char>();
        final out = arena<Pointer<OrtSession>>();
        _api.check(_api.createSession(_env, nativePath, options.value, out));
        return out.value;
      } finally {
        _api.releaseSessionOptions(options.value);
      }
    });
    final model = OrtModel._(this, session);
    _models.add(model);
    return model;
  }

  /// Releases every model loaded from this runtime and the runtime itself.
  void dispose() {
    for (final model in _models) {
      model._release();
    }
    _models.clear();
    _api.releaseRunOptions(_runOptions);
    _api.releaseMemoryInfo(_memoryInfo);
    _api.releaseEnv(_env);
  }
}

/// A loaded model (an ONNX Runtime session).
final class OrtModel {
  final OnnxRuntime _runtime;
  Pointer<OrtSession> _session;

  OrtModel._(this._runtime, this._session);

  _Api get _api => _runtime._api;

  /// Runs the model on float32 [inputs] and returns the requested float32
  /// [outputs], copied into Dart memory.
  Map<String, FloatTensor> run(
    Map<String, FloatTensor> inputs,
    List<String> outputs,
  ) {
    if (_session == nullptr) throw StateError('Model has been disposed');
    return using((arena) {
      final inputNames = arena<Pointer<Char>>(inputs.length);
      final inputValues = arena<Pointer<OrtValue>>(inputs.length);
      final outputNames = arena<Pointer<Char>>(outputs.length);
      final outputValues = arena<Pointer<OrtValue>>(outputs.length);
      try {
        var i = 0;
        for (final MapEntry(key: name, value: tensor) in inputs.entries) {
          inputNames[i] = name.toNativeUtf8(allocator: arena).cast();
          inputValues[i] = _createTensor(tensor, arena);
          i++;
        }
        for (var j = 0; j < outputs.length; j++) {
          outputNames[j] = outputs[j].toNativeUtf8(allocator: arena).cast();
        }
        _api.check(
          _api.run(
            _session,
            _runtime._runOptions,
            inputNames,
            inputValues,
            inputs.length,
            outputNames,
            outputs.length,
            outputValues,
          ),
        );
        return {
          for (var j = 0; j < outputs.length; j++)
            outputs[j]: _readTensor(outputValues[j], arena),
        };
      } finally {
        for (var k = 0; k < inputs.length; k++) {
          if (inputValues[k] != nullptr) _api.releaseValue(inputValues[k]);
        }
        for (var k = 0; k < outputs.length; k++) {
          if (outputValues[k] != nullptr) _api.releaseValue(outputValues[k]);
        }
      }
    });
  }

  /// Wraps [tensor] in an OrtValue backed by native memory owned by [arena].
  Pointer<OrtValue> _createTensor(FloatTensor tensor, Arena arena) {
    final data = arena<Float>(tensor.data.length);
    data.asTypedList(tensor.data.length).setAll(0, tensor.data);
    final shape = arena<Int64>(tensor.shape.length);
    shape.asTypedList(tensor.shape.length).setAll(0, tensor.shape);
    final out = arena<Pointer<OrtValue>>();
    _api.check(
      _api.createTensorWithData(
        _runtime._memoryInfo,
        data.cast(),
        tensor.data.length * sizeOf<Float>(),
        shape,
        tensor.shape.length,
        ONNXTensorElementDataType.ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT.value,
        out,
      ),
    );
    return out.value;
  }

  FloatTensor _readTensor(Pointer<OrtValue> value, Arena arena) {
    final info = arena<Pointer<OrtTensorTypeAndShapeInfo>>();
    _api.check(_api.getTensorTypeAndShape(value, info));
    final List<int> shape;
    try {
      final count = arena<Size>();
      _api.check(_api.getDimensionsCount(info.value, count));
      final dims = arena<Int64>(count.value);
      _api.check(_api.getDimensions(info.value, dims, count.value));
      shape = List<int>.of(dims.asTypedList(count.value));
    } finally {
      _api.releaseTensorTypeAndShapeInfo(info.value);
    }
    final length = shape.fold<int>(1, (a, b) => a * b);
    final data = arena<Pointer<Void>>();
    _api.check(_api.getTensorMutableData(value, data));
    return FloatTensor(
      Float32List.fromList(data.value.cast<Float>().asTypedList(length)),
      shape,
    );
  }

  void _release() {
    if (_session == nullptr) return;
    _api.releaseSession(_session);
    _session = nullptr;
  }

  /// Releases the session. The model cannot be used afterwards.
  void dispose() {
    _release();
    _runtime._models.remove(this);
  }
}
