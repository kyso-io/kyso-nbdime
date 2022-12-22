import os

import nbformat
from flask import Flask, request
from flask_cors import CORS
from werkzeug.utils import secure_filename

from nbdime.diffing.notebooks import diff_notebooks

app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = "/tmp"


def get_diff_notebooks(source_file_path, target_file_path):
    content_base_file = nbformat.read(source_file_path, as_version=4)
    content_remote_file = nbformat.read(target_file_path, as_version=4)
    return {
        "base": content_base_file,
        "diff": diff_notebooks(content_base_file, content_remote_file)
    }


@app.route('/diff', methods=['GET'])
def get_diff_files():
    source_file_path = request.args.get('source')
    if source_file_path is None:
        return 'Missing source file path', 400
    if not source_file_path.endswith('.ipynb'):
        return 'Base file is not a jupyter file', 400
    if not os.path.exists(source_file_path):
        return 'Base file does not exist', 400
    target_file_path = request.args.get('target')
    if target_file_path is None:
        return 'Missing target file path', 400
    if not target_file_path.endswith('.ipynb'):
        return 'Remote file is not a jupyter file', 400
    if not os.path.exists(target_file_path):
        return 'Remote file does not exist', 400
    result = get_diff_notebooks(source_file_path, target_file_path)
    return result, 200


@app.route('/diff', methods=['POST'])
def post_diff_files():
    if "source" not in request.files:
        return "Missing source file", 400
    if "target" not in request.files:
        return "Missing target file", 400
    base_file = request.files["source"]
    if not base_file.filename.endswith('.ipynb'):
        return "Base file is not a jupyter file", 400
    remote_file = request.files["target"]
    if not remote_file.filename.endswith('.ipynb'):
        return "Remote file is not a jupyter file", 400
    random_source_file_name = os.urandom(16).hex() + '.ipynb'
    source_file_path = os.path.join(UPLOAD_FOLDER, secure_filename(random_source_file_name))
    base_file.save(source_file_path)
    random_target_file_name = os.urandom(16).hex() + '.ipynb'
    target_file_path = os.path.join(UPLOAD_FOLDER, secure_filename(random_target_file_name))
    remote_file.save(target_file_path)
    result = get_diff_notebooks(source_file_path, target_file_path)
    os.remove(source_file_path)
    os.remove(target_file_path)
    return result, 200


if __name__ == '__main__':
    app.run()
