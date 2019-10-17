$wxver = "3.1.3-20191030"
$ver = "0.9.7"
$optdir = @{
    x86 = "C:\opt (x86)"
    x64 = "C:\opt"
}
$prefix = @{
    x86 = "vc"
    x64 = "vc_x64"
}
$sdkver = ""

function SetupEnvironment([string]$platform, [string]$sdkver)
{
    # Default to our vc140 install path unless we find a newer install
    $vcvars = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"

    # Try newer visual studio versions first in order to get a newer version of msbuild which may be required
    # Newer installs won't pickup the correct msbuild when executing vcvarsall from the old path
    $basePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio"
    gci -dir "$basePath" | % {
        gci -dir $_.FullName | % {
        	$verPath = $_.FullName
        	$filePath = "$verPath\VC\Auxiliary\Build\vcvarsall.bat"
	        if (Test-Path "$filePath")
	        {
	            $vcvars = $filePath
	        }
        }
    }

    # Is there a better way to get the environment than this?
    "$vcvars $platform $sdkver"
    cmd /c "`"$vcvars`" $platform $sdkver & set" | % { Invoke-Expression "`${env:$_`"".Replace("=", "}=`"") } 2>$null
}

function GetPlatform([string]$platform)
{
    if ($platform -eq "x86")
    {
        return "Win32"
    }

    return $platform
}

foreach ($platform in "x64", "x86")
{
    SetupEnvironment $platform $sdkver
    $slnPlatform = GetPlatform $platform

    ${env:WXWIN} = $optdir.$platform + "\wxWidgets\${wxver}_vc14"
    pushd build
	msbuild /m wxpdfdoc_vc14.sln /p:Configuration="DLL Debug" /p:Platform=$slnPlatform /p:wxToolkitDllNameSuffix=_vc_xdv /p:PlatformToolset=v140
	msbuild /m wxpdfdoc_vc14.sln /p:Configuration="DLL Release" /p:Platform=$slnPlatform /p:wxToolkitDllNameSuffix=_vc_xdv /p:PlatformToolset=v140
    popd

    "Copying output..."
    $outdir = $optdir.$platform + "\wxPdfDocument\$ver-${wxver}_vc14"
    $libprefix = $prefix.$platform
    mkdir -p "$outdir\lib\"
    cp -r "lib\${libprefix}_dll\" "$outdir\lib\"
    cp -r "include\" "$outdir\"
    "Done!"
    ""
}
