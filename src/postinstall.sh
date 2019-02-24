#!/bin/bash

set +x

function contains {
    [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]] && return 0 || return 1;
}

function parseAndCheckGEMSRC {
    if [[ ! -f "$INIT_CWD/.trigorc" ]]; then
        echo "ERROR: No .trigorc file found! Creating default \"APP_TYPE=node-library\""
        echo "APP_TYPE=node-service" > $INIT_CWD/.gemsrc
    fi

    if [[ -f "$INIT_CWD/.trigorc" ]]; then
        echo "Reading .trigorc..."
        . $INIT_CWD/.trigorc
    fi

    if `contains "${VALID_APP_TYPES}" "${APP_TYPE}"`; then
        echo "Setup ${APP_TYPE}";
    else
        echo "ERROR: invalid APP_TYPE: ${APP_TYPE}"
        exit 1
    fi
}

case "$INIT_CWD" in *trigo-scripts)
   echo Own Package. Exiting
    exit 0
esac

# Fixup unix tools for different environments
SED=sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED=gsed;
fi

# Defaults
VALID_APP_TYPES="react node-service node-library"

APP_TYPE=node-service

parseAndCheckGEMSRC

# merge plain text files by comment marker
if [[  ! -f "$INIT_CWD/.gitignore" ]]; then
    cp -fv src/files/generated-marker $INIT_CWD/.gitignore;
fi
${SED} -i -ne "/### BEGIN GENERATED CONTENT ###/ {p; r src/files/gitignore" -e ":a; n; /### END GENERATED CONTENT ###/ {p; b}; ba}; p" $INIT_CWD/.gitignore

for FILENAME in .editorconfig .eslintignore .prettierignore .dockerignore
do
	if [[  ! -f "$INIT_CWD/$FILENAME" ]]; then
        cp -fv src/files/generated-marker $INIT_CWD/$FILENAME;
    fi
	${SED} -i -ne "/### BEGIN GENERATED CONTENT ###/ {p; r $FILENAME" -e ":a; n; /### END GENERATED CONTENT ###/ {p; b}; ba}; p" $INIT_CWD/$FILENAME
done

if [ ! -f "$INIT_CWD/.eslintrc.json" ]; then
    cp -f src/files/.eslintrc.node.json $INIT_CWD/.eslintrc.json
fi

# merge json files by overwriting existing keys but keep extra keys
if [ -f "$INIT_CWD/package.json" ]; then
    jq -s 'reduce .[] as $d ({}; . *= $d)' $INIT_CWD/package.json src/files/package-template.json > $INIT_CWD/packagetmp.json
    mv -f $INIT_CWD/packagetmp.json $INIT_CWD/package.json
fi

if [ $APP_TYPE = "react" ]
then
    jq -s add $INIT_CWD/.eslintrc.json src/files/.eslintrc.react.json > $INIT_CWD/.eslinttmp.json
else
    jq -s add $INIT_CWD/.eslintrc.json src/files/.eslintrc.node.json > $INIT_CWD/.eslinttmp.json
fi

mv -f $INIT_CWD/.eslinttmp.json $INIT_CWD/.eslintrc.json

# immutable files
cp -f .prettierrc.json $INIT_CWD
cp -f src/files/.nvmrc $INIT_CWD

# install peer dependencies
(
    pushd "../../.."
    npm info "@trigo/trigo-scripts@latest" peerDependencies --json | command ${SED} 's/[\{\},]//g ; s/: /@/g' | xargs npm install --save-dev
    npm info "eslint-config-trigo@latest" peerDependencies --json | command ${SED} 's/[\{\},]//g ; s/: /@/g' | xargs npm install --save-dev
)
