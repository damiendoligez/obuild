open Types
open Ext
open Filepath

exception NotADirectory
exception DoesntExist
exception SetupDoesntExist

let distPath = wrap_filepath "dist"
let setupPath = wrap_filepath (distPath.filepath </> "setup")

let check f =
    if Sys.file_exists distPath.filepath
        then (if Sys.is_directory distPath.filepath
                then ()
                else raise NotADirectory
        ) else
            f ()

let checkOrFail () = check (fun () -> raise DoesntExist)
let checkOrCreate () = check (fun () -> Unix.mkdir distPath.filepath 0o755)

type buildType = Autogen | Library of string | Executable of string

let createBuildDest buildtype =
    let buildDir = wrap_filepath (distPath.filepath </> "build") in
    let _ = Filesystem.mkdirSafe buildDir 0o755 in
    match buildtype with
    | Library l    ->
           let libDir = wrap_filepath (buildDir.filepath </> "lib-" ^ l) in
           let _ = Filesystem.mkdirSafe libDir 0o755 in
           libDir
    | Autogen      ->
           let autoDir = wrap_filepath (buildDir.filepath </> "autogen") in
           let _ = Filesystem.mkdirSafe autoDir 0o755 in
           autoDir
    | Executable e ->
           let exeDir = wrap_filepath (buildDir.filepath </> e) in
           let _ = Filesystem.mkdirSafe exeDir 0o755 in
           exeDir

let read_setup () =
    try
        let content = Filesystem.readFile setupPath in
        List.map (fun l -> second (default "") $ Utils.toKV l) $ string_split '\n' content
    with _ -> raise SetupDoesntExist

let write_setup setup =
    let kv (k,v) = k ^ ": " ^ v in
    Filesystem.writeFile setupPath (String.concat "\n" $ List.map kv setup)