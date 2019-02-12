#!/bin/bash

case "$INIT_CWD" in *trigo-scripts)
   echo Own Package. Exiting
    exit 0
esac

APP_TYPE=node

if [ -f "$INIT_CWD/.trigorc" ]; then
    . $INIT_CWD/.trigorc
fi

# merge plain text files by comment marker
cp -n files/generated-marker $INIT_CWD/.gitignore
sed -i -ne "/### BEGIN GENERATED CONTENT ###/ {p; r files/gitignore" -e ":a; n; /### END GENERATED CONTENT ###/ {p; b}; ba}; p" $INIT_CWD/.gitignore

for FILENAME in .editorconfig .eslintignore .prettierignore .dockerignore
do
	cp -n files/generated-marker $INIT_CWD/$FILENAME
	sed -i -ne "/### BEGIN GENERATED CONTENT ###/ {p; r $FILENAME" -e ":a; n; /### END GENERATED CONTENT ###/ {p; b}; ba}; p" $INIT_CWD/$FILENAME
done

cp -n files/generated-marker $INIT_CWD/Makefile
sed -i -ne "/### BEGIN GENERATED CONTENT ###/ {p; r files/Makefile" -e ":a; n; /### END GENERATED CONTENT ###/ {p; b}; ba}; p" $INIT_CWD/Makefile

if [ ! -f "$INIT_CWD/.eslintrc.json" ]; then
    cp -f files/.eslintrc.node.json $INIT_CWD/.eslintrc.json
fi

# merge json files by overwriting existing keys but keep extra keys
if [ $APP_TYPE = "react" ]
then
    jq -s add $INIT_CWD/.eslintrc.json files/.eslintrc.react.json > $INIT_CWD/.eslinttmp.json
else
    jq -s add $INIT_CWD/.eslintrc.json files/.eslintrc.node.json > $INIT_CWD/.eslinttmp.json
fi
mv -f $INIT_CWD/.eslinttmp.json $INIT_CWD/.eslintrc.json

if [ -f "$INIT_CWD/package.json" ]; then
    jq -s 'reduce .[] as $d ({}; . *= $d)' $INIT_CWD/package.json files/package-template.json > $INIT_CWD/packagetmp.json
    mv -f $INIT_CWD/packagetmp.json $INIT_CWD/package.json
fi

# immutable files
cp -f .prettierrc.json $INIT_CWD
cp -f CONTRIBUTING.md $INIT_CWD
cp -f GUIDELINES.md $INIT_CWD
cp -f LICENSE.md $INIT_CWD
cp -f files/README.md $INIT_CWD
cp -f files/.nvmrc $INIT_CWD
cp -f files/Dockerfile $INIT_CWD
cp -f files/Jenkinsfile $INIT_CWD

# install peer dependencies

(pushd "../../.." && npx install-peerdeps @trigo/trigo-scripts --auth $NPM_TOKEN --only-peers && npx install-peerdeps eslint-config-trigo --only-peers)
