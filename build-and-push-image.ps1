#!/usr/bin/pwsh

param(
    # ".env.secret"
    [string] $EnvFilePath = "",
    [string] $BuildTag = "latest",
    # tumwfml-statum1.srv.mwn.de:5000
    [Parameter(Mandatory = $true)] [string] $DockerId
)

$build_arg_str = ""
if (!$EnvFilePath -eq "") {
    # Load the build arguments for 'docker build' and the corresponding Dockerfile
    $build_args = Get-Content -Raw -Path $EnvFilePath | ConvertFrom-StringData
    # Convert all keys to lowercase letters before adding as a build argument
    foreach ($key in $build_args.PSBase.Keys) {
        $build_arg_str += " --build-arg $($key.ToString())=$($build_args[$key])"
    }
}

$desired_archs = @("linux/386", "linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64")
[string] $existing_archs = (docker buildx inspect) | Out-String
foreach ($arch in $desired_archs) {
    if ( ! $existing_archs.Contains($arch)) {
        docker run --rm --privileged "multiarch/qemu-user-static" --reset -p yes
        docker buildx create --node multiarch_builder --name multiarch_builder
        docker buildx use multiarch_builder
        docker buildx inspect --bootstrap
        break
    }
}
$dockerfile_path = "./Dockerfile"
$build_context_path = "."
$build_tag = "${DockerId}/tatum-edge-node-red:${BuildTag}"
$docker_build_cmd = "docker buildx build -f ${dockerfile_path} -t ${build_tag} --platform $([System.String]::Join(",", $desired_archs)) --push ${build_context_path}"
$docker_build_cmd += $build_arg_str
Invoke-Expression -Command $docker_build_cmd
