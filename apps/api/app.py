#!/usr/bin/env python3
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def health():
    """Endpoint de salud"""
    return jsonify({
        'status': 'healthy',
        'message': 'App esta funcionando correctamente en ECS'
    })

@app.route('/api/version', methods=['GET'])
def version():
    """Endpoint de versión"""
    return jsonify({
        'version': '1.0.0',
        'environment': 'production'
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
