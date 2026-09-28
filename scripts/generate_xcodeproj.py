#!/usr/bin/env python3
"""Generates Corgify.xcodeproj for the iOS app target.

Written by hand rather than with XcodeGen or Tuist so the repo needs no
extra tooling: a clean checkout can produce the project with the system
Python alone.

The app target compiles App/Corgify/ and links the local CorgifyCore
Swift package.

Usage: python3 scripts/generate_xcodeproj.py
"""
import os
import pathlib
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Corgify.xcodeproj"

# Stable 24-hex identifiers. Xcode only requires uniqueness within the file.
IDS = {
    "rootObject": "AA0000000000000000000001",
    "mainGroup": "AA0000000000000000000002",
    "productsGroup": "AA0000000000000000000003",
    "appTarget": "AA0000000000000000000004",
    "buildConfigListProject": "AA0000000000000000000005",
    "buildConfigListTarget": "AA0000000000000000000006",
    "debugProject": "AA0000000000000000000007",
    "releaseProject": "AA0000000000000000000008",
    "debugTarget": "AA0000000000000000000009",
    "releaseTarget": "AA000000000000000000000A",
    "sourcesPhase": "AA000000000000000000000B",
    "frameworksPhase": "AA000000000000000000000C",
    "resourcesPhase": "AA000000000000000000000D",
    "productRef": "AA000000000000000000000E",
    "appGroup": "AA000000000000000000000F",
    "appFileApp": "AA0000000000000000000010",
    "appFileCamera": "AA0000000000000000000011",
    "buildFileApp": "AA0000000000000000000012",
    "buildFileCamera": "AA0000000000000000000013",
    "packageRef": "AA0000000000000000000014",
    "packageDep": "AA0000000000000000000015",
    "buildFilePackage": "AA0000000000000000000016",
    "infoPlist": "AA0000000000000000000017",
}

INFO_PLIST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDevelopmentRegion</key>
\t<string>en</string>
\t<key>CFBundleDisplayName</key>
\t<string>Corgify</string>
\t<key>CFBundleExecutable</key>
\t<string>$(EXECUTABLE_NAME)</string>
\t<key>CFBundleIdentifier</key>
\t<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
\t<key>CFBundleInfoDictionaryVersion</key>
\t<string>6.0</string>
\t<key>CFBundleName</key>
\t<string>$(PRODUCT_NAME)</string>
\t<key>CFBundlePackageType</key>
\t<string>APPL</string>
\t<key>CFBundleShortVersionString</key>
\t<string>0.1</string>
\t<key>CFBundleVersion</key>
\t<string>1</string>
\t<key>NSCameraUsageDescription</key>
\t<string>Corgify uses the camera to photograph a face and turn it into a corgi. Photos stay on your device.</string>
\t<key>UILaunchScreen</key>
\t<dict/>
\t<key>UISupportedInterfaceOrientations</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t</array>
</dict>
</plist>
"""

PBXPROJ = """// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
\t\t{buildFileApp} /* CorgifyApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {appFileApp} /* CorgifyApp.swift */; }};
\t\t{buildFileCamera} /* CameraView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {appFileCamera} /* CameraView.swift */; }};
\t\t{buildFilePackage} /* CorgifyCore in Frameworks */ = {{isa = PBXBuildFile; productRef = {packageDep} /* CorgifyCore */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{productRef} /* Corgify.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Corgify.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{appFileApp} /* CorgifyApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CorgifyApp.swift; sourceTree = "<group>"; }};
\t\t{appFileCamera} /* CameraView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CameraView.swift; sourceTree = "<group>"; }};
\t\t{infoPlist} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworksPhase} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{buildFilePackage} /* CorgifyCore in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{mainGroup} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{appGroup} /* Corgify */,
\t\t\t\t{productsGroup} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{productsGroup} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{productRef} /* Corgify.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{appGroup} /* Corgify */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{appFileApp} /* CorgifyApp.swift */,
\t\t\t\t{appFileCamera} /* CameraView.swift */,
\t\t\t\t{infoPlist} /* Info.plist */,
\t\t\t);
\t\t\tpath = App/Corgify;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{appTarget} /* Corgify */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {buildConfigListTarget} /* Build configuration list for PBXNativeTarget "Corgify" */;
\t\t\tbuildPhases = (
\t\t\t\t{sourcesPhase} /* Sources */,
\t\t\t\t{frameworksPhase} /* Frameworks */,
\t\t\t\t{resourcesPhase} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = Corgify;
\t\t\tpackageProductDependencies = (
\t\t\t\t{packageDep} /* CorgifyCore */,
\t\t\t);
\t\t\tproductName = Corgify;
\t\t\tproductReference = {productRef} /* Corgify.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{rootObject} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 2700;
\t\t\t\tLastUpgradeCheck = 2700;
\t\t\t}};
\t\t\tbuildConfigurationList = {buildConfigListProject} /* Build configuration list for PBXProject "Corgify" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {mainGroup};
\t\t\tpackageReferences = (
\t\t\t\t{packageRef} /* XCLocalSwiftPackageReference "." */,
\t\t\t);
\t\t\tproductRefGroup = {productsGroup} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{appTarget} /* Corgify */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resourcesPhase} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sourcesPhase} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{buildFileApp} /* CorgifyApp.swift in Sources */,
\t\t\t\t{buildFileCamera} /* CameraView.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debugProject} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.4;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{releaseProject} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.4;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debugTarget} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "App/Corgify/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 0.1;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.junhwanlee.corgify;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{releaseTarget} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "App/Corgify/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 0.1;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.junhwanlee.corgify;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{buildConfigListProject} /* Build configuration list for PBXProject "Corgify" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debugProject} /* Debug */,
\t\t\t\t{releaseProject} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{buildConfigListTarget} /* Build configuration list for PBXNativeTarget "Corgify" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debugTarget} /* Debug */,
\t\t\t\t{releaseTarget} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
\t\t{packageRef} /* XCLocalSwiftPackageReference "." */ = {{
\t\t\tisa = XCLocalSwiftPackageReference;
\t\t\trelativePath = .;
\t\t}};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
\t\t{packageDep} /* CorgifyCore */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tproductName = CorgifyCore;
\t\t}};
/* End XCSwiftPackageProductDependency section */
\t}};
\trootObject = {rootObject} /* Project object */;
}}
"""

SCHEME = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2700" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{appTarget}"
               BuildableName = "Corgify.app"
               BlueprintName = "Corgify"
               ReferencedContainer = "container:Corgify.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{appTarget}"
            BuildableName = "Corgify.app"
            BlueprintName = "Corgify"
            ReferencedContainer = "container:Corgify.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{appTarget}"
            BuildableName = "Corgify.app"
            BlueprintName = "Corgify"
            ReferencedContainer = "container:Corgify.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"></ArchiveAction>
</Scheme>
"""


def render(template, ids):
    """Substitutes {key} tokens without touching the literal braces that
    pbxproj syntax requires. str.format cannot be used here for that reason."""
    out = template
    for key, value in ids.items():
        out = out.replace("{" + key + "}", value)
    return out.replace("{{", "{").replace("}}", "}")


def main():
    if PROJECT.exists():
        shutil.rmtree(PROJECT)

    (ROOT / "App" / "Corgify" / "Info.plist").write_text(INFO_PLIST)

    PROJECT.mkdir(parents=True)
    (PROJECT / "project.pbxproj").write_text(render(PBXPROJ, IDS))

    schemes = PROJECT / "xcshareddata" / "xcschemes"
    schemes.mkdir(parents=True)
    (schemes / "Corgify.xcscheme").write_text(render(SCHEME, IDS))

    print(f"Generated {PROJECT.relative_to(ROOT)}")
    print("Build: xcodebuild -project Corgify.xcodeproj -scheme Corgify "
          "-destination 'platform=iOS Simulator,name=iPhone 17' build")


if __name__ == "__main__":
    main()
