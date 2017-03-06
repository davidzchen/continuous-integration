:: Copyright 2016 The Bazel Authors. All rights reserved.
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::    http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.

:: ATTENTION: This file is auto-generated from a template.
:: See https://github.com/bazelbuild/continuous-integration/blob/master/jenkins/github-jobs.bat.tpl

:: Batch script containing the main build phase for windows bazel_github_job-s
@echo on
set BAZEL_SH=c:\tools\msys64\usr\bin\bash.exe

set BAZEL=c:\bazel_ci\installs\%BAZEL_VERSION%\bazel.exe
set TMPDIR=c:\bazel_ci\temp

:: Verify that BAZEL_VERSION is not empty and BAZEL exists.
echo CI info: BAZEL_VERSION=(%BAZEL_VERSION%)
echo CI info: BAZEL=(%BAZEL%)

:: Check BAZEL_VERSION, it should be defined by Jenkins.
if "%BAZEL_VERSION%" == "" (
  echo ERROR: BAZEL_VERSION is empty
  exit /b 1
)

:: Check if BAZEL exists.
if exist "%BAZEL%" (
  echo CI info: BAZEL binary found
) else (
  echo CI ERROR: BAZEL not found
  exit /b 1
)

:: In src/main/native/build_windows_jni.sh, we use `sort --version-sort`
:: So we need to make sure find the msys sort instead of windows sort.
:: TODO(pcloudy): remove this after MSVC toolchain becomes default, because
:: at that time we can build dll by cc_binary for `bazel build src:bazel`.
set PATH=c:\tools\msys64\usr\bin;%PATH%

set ROOT=%cd%
set BAZELRC=%ROOT%\.bazelrc
del /q /f %BAZELRC%
echo build {{ variables.BUILD_OPTS }} >> %BAZELRC%
:: Host C++ toolchain still needs to be MSYS because protoc.exe built with MSVC is broken.
:: TODO(pcloudy): Remove following after fixing https://github.com/bazelbuild/bazel/issues/2634
if "%BAZEL_VERSION%" == "HEAD" (
  echo build --host_cpu=x64_windows_msys >> %BAZELRC%
)
echo test {{ variables.TEST_OPTS }} >> %BAZELRC%
echo test --test_tag_filters {{ variables.TEST_TAG_FILTERS }},-no_windows >> %BAZELRC%
echo test --define JAVA_VERSION=1.8 >> %BAZELRC%

call:bazel version

del /q /f .unstable

:: Expand variables.WINDOWS_CONFIGURE
{{ variables.WINDOWS_CONFIGURE }}

:: Check variables.WINDOWS_BUILDS
if not "{{ variables.WINDOWS_BUILDS }}" == "" (
  call:bazel build --copt=/w --cpu=x64_windows_msvc {{ variables.WINDOWS_BUILDS }}
)

:: Check variables.WINDOWS_TESTS
if not "{{ variables.WINDOWS_TESTS }}" == "" (
  call:bazel test --copt=/w --cpu=x64_windows_msvc {{ variables.WINDOWS_TESTS }}
)

if "%BAZEL_VERSION%" == "HEAD" (
  set EXTRA_CPU_OPTION=--cpu=x64_windows_msys
)

:: Check variables.WINDOWS_BUILDS_MSYS
if not "{{ variables.WINDOWS_BUILDS_MSYS }}" == "" (
  call:bazel build %EXTRA_CPU_OPTION% {{ variables.WINDOWS_BUILDS_MSYS }}
)

:: Check variables.WINDOWS_TESTS_MSYS
if not "{{ variables.WINDOWS_TESTS_MSYS }}" == "" (
  call:bazel test %EXTRA_CPU_OPTION%  {{ variables.WINDOWS_TESTS_MSYS }}
)

exit %errorlevel%

:bazel
%BAZEL% --bazelrc=%BAZELRC% %*
set retCode=%errorlevel%
if %retCode%==3 (
  :: Write 1 in the .unstable file so the following step in Jenkins
  :: knows that it is a test failure.
  echo 1 > %ROOT%\.unstable
) else (
  if not %retCode%==0 (
    :: Else simply fail the job by exiting with a non-null return code.
    exit %retCode%
  )
)
exit /b 0
