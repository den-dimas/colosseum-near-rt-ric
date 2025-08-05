import logging
import json
from xapp_control import *


def main():
    logging.basicConfig(level=logging.DEBUG, filename='/home/xapp-logger.log', filemode='a+',
                        format='%(asctime)-15s %(levelname)-8s %(message)s')
    formatter = logging.Formatter('%(asctime)-15s %(levelname)-8s %(message)s')
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(formatter)
    logging.getLogger('').addHandler(console)
    
    control_sck = open_control_socket(4200)

    while True:
        try:
            data = receive_from_socket(control_sck)

            if not data:
                logging.warning("No data received. Waiting for KPM data from xapp-sm-connector...")
                continue
            
            kpm_data_str = data
            logging.info("Received KPM data from xapp-sm-connector: %s", kpm_data_str)
            
            kpm_data = json.loads(kpm_data_str)
            
            cell_load = kpm_data.get('cell_load', 0)
            bandwidth_adjustment = 0

            if cell_load > 0.8:
                logging.info("High cell load detected (%.2f). Suggesting to increase bandwidth.", cell_load)
                bandwidth_adjustment = 10 
            else:
                logging.info("Low cell load detected (%.2f). Suggesting to decrease bandwidth.", cell_load)
                bandwidth_adjustment = -5 

            control_message_params = {
                "bandwidth_adjustment": bandwidth_adjustment,
                "target_gnb": "gnb:131-133-31000000"
            }
            control_message_json = json.dumps(control_message_params)
            
            bytes_num = control_sck.send(control_message_json.encode("utf-8"))
            logging.info("Socket sent %d bytes with JSON payload: %s", bytes_num, control_message_json)
            
            logging.info('====================================')
            logging.info('Control cycle complete.')
            logging.info('====================================\n')
            
        except (socket.error, json.JSONDecodeError) as e:
            logging.error("An error occurred during socket communication: %s", e)
            break
    
    control_sck.close()


if __name__ == '__main__':
    main()