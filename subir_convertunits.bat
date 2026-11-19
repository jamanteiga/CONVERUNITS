@echo off
setlocal

rem ============================================================
rem  Sube todo el contenido de esta carpeta al repositorio
rem  CONVERTUNITS de GitHub. No pregunta nada ni pide teclas.
rem  Resultado en: subir_convertunits_log.txt
rem  App publicada en: https://jamanteiga.github.io/CONVERTUNITS/
rem ============================================================

set "REPO_DIR=C:\Users\jaman\Documents\PROYECTOS\CONVERUNITS"
set "GH_USER=jamanteiga"
set "REPO_NAME=CONVERTUNITS"
set "REPO_URL=https://github.com/%GH_USER%/%REPO_NAME%.git"
set "LOG_FILE=%~dp0subir_convertunits_log.txt"
set "GIT_TERMINAL_PROMPT=0"

echo ===== %date% %time% ===== > "%LOG_FILE%"

if not exist "%REPO_DIR%" (
    echo ERROR: no existe la carpeta %REPO_DIR% >> "%LOG_FILE%"
    goto FIN
)

cd /d "%REPO_DIR%"
if errorlevel 1 (
    echo ERROR: no se pudo entrar en %REPO_DIR% >> "%LOG_FILE%"
    goto FIN
)

rem --- Si esta instalado GitHub CLI (gh): crea el repositorio si no existe ---
where gh >nul 2>&1
if errorlevel 1 goto SIN_GH
gh repo view %GH_USER%/%REPO_NAME% >nul 2>&1
if errorlevel 1 (
    echo El repositorio no existe en GitHub. Creandolo... >> "%LOG_FILE%"
    gh repo create %GH_USER%/%REPO_NAME% --public --description "Conversor de unidades y divisas" >> "%LOG_FILE%" 2>&1
)
:SIN_GH

if not exist ".git" (
    echo Esta carpeta aun no es un repositorio git. Inicializando... >> "%LOG_FILE%"
    git init >> "%LOG_FILE%" 2>&1
    git branch -M main >> "%LOG_FILE%" 2>&1
    git remote add origin "%REPO_URL%" >> "%LOG_FILE%" 2>&1
) else (
    git remote get-url origin >nul 2>&1
    if errorlevel 1 (
        git remote add origin "%REPO_URL%" >> "%LOG_FILE%" 2>&1
    )
)

rem --- Identidad de git solo si no esta configurada ---
git config user.name >nul 2>&1
if errorlevel 1 git config user.name "%GH_USER%"
git config user.email >nul 2>&1
if errorlevel 1 git config user.email "%GH_USER%@users.noreply.github.com"

echo Preparando todos los ficheros de %REPO_DIR%... >> "%LOG_FILE%"
git add -A >> "%LOG_FILE%" 2>&1

git diff --cached --quiet
if errorlevel 1 (
    echo Creando commit... >> "%LOG_FILE%"
    git commit -m "Actualizacion automatica CONVERTUNITS %date% %time%" >> "%LOG_FILE%" 2>&1
) else (
    echo No hay cambios nuevos respecto al ultimo commit local. >> "%LOG_FILE%"
)

echo Subiendo todo a GitHub (esta copia local manda: sobrescribe lo que hubiera en GitHub)... >> "%LOG_FILE%"
git push origin main --force >> "%LOG_FILE%" 2>&1
if errorlevel 1 (
    echo ERROR al subir a GitHub ^(git push^). Puede que haga falta iniciar sesion una vez a mano. >> "%LOG_FILE%"
    goto FIN
)
echo Subida completada correctamente. >> "%LOG_FILE%"

rem --- Con gh: activa GitHub Pages (rama main, raiz). Si ya estaba activo, no pasa nada ---
where gh >nul 2>&1
if errorlevel 1 goto FIN
gh api -X POST repos/%GH_USER%/%REPO_NAME%/pages -f "source[branch]=main" -f "source[path]=/" >> "%LOG_FILE%" 2>&1
echo GitHub Pages activado o ya existente. La app estara en https://%GH_USER%.github.io/%REPO_NAME%/ en 1-2 minutos. >> "%LOG_FILE%"

:FIN
echo ===== Fin: %date% %time% ===== >> "%LOG_FILE%"
endlocal
exit
